import Elm from '../elm/Popup.elm';
import {
  isEmpty,
} from 'ramda';
import {
  EventGetSimilarPages
} from 'Common/constants'
import {
  indexingStatus,
  setIndexingStatus,
  getOption,
} from 'Common/option'
import {
  openUrl,
  getSyncStorage,
  getLocalStorage
} from 'Common/chrome';

(async () => {
  const option = await getSyncStorage('option');
  const {
    tags
  } = getOption(option);

  tags.sort();

  const app = Elm.Popup.fullscreen({
    suspend: indexingStatus(),
    query: '',
    tags,
    items: []
  });

  app.ports.openSearchPage.subscribe((query) => {
    openUrl(`${chrome.extension.getURL("option/index.html")}?q=${query}`, true);
  });

  app.ports.suspend.subscribe(status => {
    setIndexingStatus(status);
    console.log('suspend', status);
  });

  // chrome.tabs.query({
  //   'active': true,
  //   'lastFocusedWindow': true
  // }, function (tabs) {
  //   const url = tabs[0].url;
  //   if (url.startsWith('http')) {
  //     chrome.runtime.sendMessage({
  //       type: EventGetSimilarPages,
  //       url,
  //     }, async (res) => {

  //       const items = res.map(v => v.label);

  //       if (isEmpty(items)) {
  //         return
  //       }

  //       const index = await getLocalStorage(res.map(v => v.label));
  //       app.ports.similarPages.send(Object.values(index).filter(v => v.url != url));
  //     });
  //   }
  // });

  ['https://fonts.googleapis.com/css?family=Open+Sans'].forEach(url => {
    const link = document.createElement('link');
    link.href = url;
    document.body.appendChild(link);
  });
})();