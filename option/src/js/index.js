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
  EventReIndexing
} from 'Common/constants'

(async () => {
  const data = await getSyncStorage('option');
  const app = Elm.Option.fullscreen(getOption(data));

  app.ports.saveSettings.subscribe(data => {
    setIndexingStatus(data.isIndexing);
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