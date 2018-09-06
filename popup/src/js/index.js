import Elm from '../elm/Popup.elm';
import {
  EventIndexing,
} from 'Common/constants'
import {
  indexingStatus,
  setIndexingStatus,
  documentCount
} from 'Common/option'
import {
  openUrl,
} from 'Common/chrome';

const app = Elm.Popup.fullscreen({
  suspend: indexingStatus(),
  query: '',
});

app.ports.openSearchPage.subscribe((query) => {
  openUrl(`${chrome.extension.getURL("option/index.html")}?q=${query}`, true);
});

app.ports.suspend.subscribe(status => {
  setIndexingStatus(status);
  console.log('suspend', status);
});