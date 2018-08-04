import {
  omit,
} from 'ramda';
import Elm from '../elm/Option.elm';
import * as iziToast from "iziToast";
import 'izitoast/dist/css/iziToast.min.css';
import {
  getSyncStorage
} from 'Common/chrome';
import {
  getOption,
  setIndexingStatus,
  deleteIndexedStatus
} from 'Common/option'
import {
  EventReIndexing,
  EventCreateIndexFromPocket
} from 'Common/constants'

(async () => {
  const data = await getSyncStorage('option');
  const app = Elm.Option.fullscreen(getOption(data));

  app.ports.saveSettings.subscribe(data => {
    setIndexingStatus(data.isIndexing);

    Object.keys(localStorage).forEach(key => {
      if (key.startsWith('indexed:')) {
        const url = key.slice(8);
        data.blockList.forEach(x => {
          if (url.indexOf(x) !== -1) {
            localStorage.removeItem(url);
            chrome.storage.local.remove(url);
            console.log(`remove index ${url}`);
          }
        });
      }
    });

    chrome.storage.sync.set({
      'option': omit(['blockKeyword', 'changed', 'isIndexing'], data)
    }, () => {
      iziToast.success({
        title: 'Saved',
        message: 'Saved successfully.',
      });
    });
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

  app.ports.reindexing.subscribe(data => {
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

  app.ports.deleteIndex.subscribe(data => {
    chrome.storage.local.clear();
    localStorage.clear();
    iziToast.success({
      title: 'Delete index',
      message: 'Deleted successfully.',
    });
    deleteIndexedStatus();
  });
})();