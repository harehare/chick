import {
  omit,
  head,
  isEmpty
} from 'ramda';
import Elm from '../elm/Option.elm';
import * as iziToast from "iziToast";
import 'izitoast/dist/css/iziToast.min.css';
import uuid5 from 'uuid/v5';
import queryString from 'query-string';
import {
  getLocalStorage,
  setLocalStorage,
  getSyncStorage,
} from 'Common/chrome';
import {
  getOption,
  documentCount,
  setIndexingStatus,
  totalDocumentCount
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
    const option = await getSyncStorage('option');
    const {
      searchApi
    } = getOption(option);

    if (searchApi.verify) {
      app.ports.callSearchApi.send([searchApi.url, queryInfo.query]);
    } else {
      app.ports.tokenizeNGram.send(queryInfo.query);
    }
  });

  app.ports.tokenizeResult.subscribe(async (tokens) => {
    app.ports.optionSearchResult.send(await doSearch(tokens, false, queryInfo ? {
      itemType: queryInfo.itemType,
      before: queryInfo.before,
      after: queryInfo.after
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
      console.log(Object.assign(indexItem[id], info));
      await setLocalStorage({
        [id]: Object.assign(indexItem[id], info)
      });
    });

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
    localStorage.setItem('pocket-indexing?', data.indexTarget.pocket)
    chrome.storage.sync.set({
      'option': omit(['blockKeyword', 'changed', 'isIndexing', 'logoUrl'], data)
    }, () => {
      iziToast.success({
        title: 'Saved',
        message: 'Saved successfully.',
      });
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

  app.ports.succeedVerify.subscribe(apiName => {
    iziToast.success({
      title: apiName,
      message: 'Succeed verification.',
    });
  });

  app.ports.failedVerify.subscribe(apiName => {
    iziToast.error({
      title: apiName,
      message: 'Failed verification.',
    });
  });

  app.ports.selectText.subscribe(id => {
    document.querySelector(`#${id}`).select();
  });

  app.ports.reindexing.subscribe(_ => {
    chrome.runtime.sendMessage({
      type: EventReIndexing,
    });
    iziToast.info({
      title: 'RE-INDEXING',
      message: 'Re-indexing is launched now!!',
    });
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
    iziToast.info({
      title: 'START IMPORT',
      message: 'Data Import is launched now!!',
    });
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
        iziToast.info({
          title: 'Import index',
          message: 'Import index is launched now!!',
        });
        document.body.removeChild(input);
      }
      reader.onerror = () => {
        iziToast.error({
          title: 'Import index',
          message: 'Failed import.',
        });
      };
      reader.readAsText(file.target.files[0]);
    };
    input.click();
  });

})();