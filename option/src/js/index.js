import {
  omit,
  head,
  isEmpty
} from 'ramda';
import Elm from '../elm/Option.elm';
import * as iziToast from "iziToast";
import 'izitoast/dist/css/iziToast.min.css';
import uuid5 from "uuid/v5";
import {
  getLocalStorage,
  setLocalStorage,
  getSyncStorage
} from 'Common/chrome';
import {
  getOption,
  documentCount,
  setIndexingStatus,
  deleteIndexedStatus
} from 'Common/option'
import {
  EventReIndexing,
  EventCreateIndexFromPocket,
  EventIndexing
} from 'Common/constants'
import {
  search as doSearch
} from 'Common/search';

(async () => {
  const data = await getSyncStorage('option');
  const option = getOption(data);
  const indexingCount = localStorage.getItem('indexingCount');
  const currentCount = localStorage.getItem('currentCount');
  const indexingComplete = localStorage.getItem('indexing_complete') === 'true';

  option.status = {
    documentCount: parseInt(indexingComplete ? documentCount() : indexingCount ? indexingCount : 0),
    indexedCount: parseInt(indexingComplete ? documentCount() : currentCount ? currentCount : 0)
  };
  const app = Elm.Option.fullscreen(option);

  app.ports.doSearch.subscribe(query => {
    if (isEmpty(query)) {
      return;
    }
    app.ports.tokenizeNGram.send(query);
  });

  app.ports.tokenizeResult.subscribe(async (tokens) => {
    app.ports.optionSearchResult.send(await doSearch(tokens, false));
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
      'option': omit(['blockKeyword', 'changed', 'isIndexing'], data)
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
      title: 'Re-indexing',
      message: 'Re-indexing is launched now!!',
    });
  });

  app.ports.importPocket.subscribe(_ => {
    chrome.runtime.sendMessage({
      type: EventCreateIndexFromPocket,
    });
    iziToast.info({
      title: 'Import pocket',
      message: 'Import pocket is launched now!!',
    });
  });

  app.ports.deleteIndex.subscribe(_ => {
    chrome.storage.local.clear();
    localStorage.clear();
    iziToast.success({
      title: 'Delete index',
      message: 'Deleted successfully.',
    });
    deleteIndexedStatus();
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
      console.log(file);
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