import {
  omit,
  head,
  isEmpty,
  flatten,
  uniq
} from 'ramda';
import Elm from '../elm/Option.elm';
import uuid5 from 'uuid/v5';
import queryString from 'query-string';
import {
  getLocalStorage,
  setLocalStorage,
  getSyncStorage,
  showNotification
} from 'Common/chrome';
import {
  getOption,
  documentCount,
  setIndexingStatus,
} from 'Common/option'
import {
  EventReIndexing,
  EventImportPocket,
  EventIndexing,
  EventImportBookmark,
  EventImportHistory
} from 'Common/constants'
import {
  search as doSearch,
  queryParser
} from 'Common/search';

(async () => {
  const data = await getSyncStorage('option');
  const option = getOption(data);
  const parsedQuery = queryString.parse(location.search);
  let queryInfo = null;

  option.query = parsedQuery.q ? parsedQuery.q : '';
  option.logoUrl = chrome.runtime.getURL('img/logo.png');
  option.status = {
    documentCount: documentCount(),
    indexedCount: documentCount()
  };
  const app = Elm.Option.fullscreen(option);

  app.ports.doSearch.subscribe(async query => {
    if (isEmpty(query)) {
      return;
    }

    queryInfo = queryParser(query);
    app.ports.tokenizeNGram.send(queryInfo.query);
  });

  app.ports.tokenizeResult.subscribe(async (tokens) => {
    app.ports.optionSearchResult.send(await doSearch(tokens, queryInfo ? {
      itemType: queryInfo.itemType,
      before: queryInfo.before,
      after: queryInfo.after,
      tag: queryInfo.tag
    } : {}));
  });

  app.ports.saveSettings.subscribe(data => {
    setIndexingStatus(data.isIndexing);

    data.deleteUrlList.forEach(url => {
      localStorage.removeItem(url);
      chrome.storage.local.remove(uuid5(url, uuid5.URL));
      console.log(`remove index ${url}`);
    });

    data.indexInfo.forEach(async info => {
      const id = uuid5(info.url, uuid5.URL);
      const indexItem = await getLocalStorage(id);
      const newItem = Object.assign(indexItem[id], info)
      await setLocalStorage({
        [id]: newItem
      });
    });

    data.tags = uniq([...data.tags, ...flatten(data.indexInfo.map(index => index.tags))]);
    Object.keys(localStorage).forEach(key => {
      if (key.startsWith('indexed:')) {
        const url = key.slice(8);
        data.blockList.forEach(x => {
          if (url.indexOf(x) !== -1) {
            localStorage.removeItem(url);
            chrome.storage.local.remove(uuid5(url, uuid5.URL));
            console.log(`remove index ${url}`);
          }
        });
      }
    });
    chrome.storage.sync.set({
      'option': omit(['blockKeyword', 'isIndexing', 'logoUrl'], data)
    });
  });

  chrome.runtime.onMessage.addListener((message) => {
    if (message.type === EventIndexing) {
      app.ports.updateStatus.send({
        documentCount: message.documentCount,
        indexedCount: message.indexedCount
      });
    }
  });

  app.ports.selectText.subscribe(id => {
    document.querySelector(`#${id}`).select();
  });

  app.ports.reindexing.subscribe(_ => {
    chrome.runtime.sendMessage({
      type: EventReIndexing,
    });
    showNotification('Re-indexing', 'Re-indexing is launched now!!')
  });

  app.ports.dataImport.subscribe(target => {
    if (target.bookmark) {
      chrome.runtime.sendMessage({
        type: EventImportBookmark
      });
    }
    if (target.history) {
      chrome.runtime.sendMessage({
        type: EventImportHistory
      });
    }
    if (target.pocket) {
      chrome.runtime.sendMessage({
        type: EventImportPocket,
      });
    }
    showNotification('Start imported', 'Data Import is launched now!!');
  });

  app.ports.export.subscribe(async _ => {
    const arr = [];
    for (const key of Object.keys(localStorage)) {
      if (key.startsWith('indexed:')) {
        const url = key.slice(8);
        const item = await getLocalStorage(uuid5(url, uuid5.URL));
        const index = head(Object.values(item));
        if (index && !isEmpty(item.itemType)) {
          arr.push(`${url}\t${index.itemType}`);
        }
      }
    }

    const a = document.createElement('a');
    document.body.appendChild(a);
    a.style = 'display: none';
    a.href = `data:text/plain;charset=utf-8,${encodeURIComponent(arr.join('\n'))}`;
    a.download = 'chick-index.tsv';
    a.click();
    document.body.removeChild(a);
  });

  app.ports.importIndex.subscribe(_ => {
    const input = document.createElement("input");
    document.body.appendChild(input);
    input.type = 'file';
    input.style = 'display:none';
    input.onchange = (file) => {
      if (!file.target.files || !file.target.files[0]) {
        return;
      }
      const reader = new FileReader();
      reader.onload = (e) => {
        chrome.runtime.sendMessage({
          type: 'IMPORT_INDEX',
          data: e.target.result
        });
        showNotification('File Import', 'File import is launched now!!')
        document.body.removeChild(input);
      }
      reader.onerror = () => {
        showNotification('File Import', 'Failed import.');
      };
      reader.readAsText(file.target.files[0]);
    };
    input.click();
  });

})();