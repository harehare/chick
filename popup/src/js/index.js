import {
  prop
} from 'ramda';
import Elm from '../elm/Popup.elm';
import {
  EventIndexing,
  EventErrorIndexing
} from 'Common/constants'
import {
  indexingStatus,
  setIndexingStatus,
  documentCount
} from 'Common/option'

const indexingCount = localStorage.getItem('indexingCount');
const currentCount = localStorage.getItem('currentCount');
const indexingComplete = localStorage.getItem('indexing_complete') === 'true';

const app = Elm.Popup.fullscreen({
  status: {
    documentCount: parseInt(indexingComplete ? documentCount() : indexingCount ? indexingCount : 0),
    indexedCount: parseInt(indexingComplete ? documentCount() : currentCount ? currentCount : 0)
  },
  suspend: indexingStatus()
});

chrome.runtime.onMessage.addListener((message) => {
  if (message.type === EventIndexing) {
    app.ports.index.send({
      documentCount: message.documentCount,
      indexedCount: message.indexedCount
    });
  }
});

app.ports.showOption.subscribe(() => {
  window.open(chrome.extension.getURL("option/index.html"));
});

app.ports.suspend.subscribe(status => {
  setIndexingStatus(status);
  console.log('suspend', status);
});