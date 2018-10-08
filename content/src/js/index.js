import Elm from '../elm/Main.elm';
import {
  findIndex,
  isEmpty
} from 'ramda';
import {
  getSyncStorage
} from 'Common/chrome';
import {
  getOption
} from 'Common/option';
import queryString from 'query-string';
import {
  search as doSearch,
  queryParser
} from 'Common/search';
import {
  EventOpenTab,
} from 'Common/constants';

const div = document.createElement('div');
document.body.appendChild(div);

(async () => {
  const option = await getSyncStorage('option');
  const {
    viewOption,
    blockList,
  } = getOption(option);

  if (!viewOption.google && location.href.startsWith('https://www.google')) {
    return;
  } else if (!viewOption.bing && location.href.startsWith('https://www.bing.com')) {
    return;
  } else if (!viewOption.duckDuckGo && location.href.startsWith('https://www.duckduckgo.com')) {
    return;
  } else if (!viewOption.yahoo && location.href.startsWith('https://yahoo')) {
    return;
  }

  const app = Elm.Main.embed(div);
  const parsedQuery = queryString.parse(location.search).q || queryString.parse(location.search).p;
  const logoUrl = chrome.runtime.getURL('img/logo.png')

  app.ports.imageUrl.send(logoUrl);
  app.ports.changeVisiblety.send(!localStorage.getItem('visible') || localStorage.getItem('visible') === 'true');

  if (isEmpty(parsedQuery)) {
    return;
  }

  const queryInfo = queryParser(parsedQuery);

  app.ports.setVisiblety.subscribe(visible => {
    localStorage.setItem('visible', visible);
  });

  app.ports.openOption.subscribe(_ => {
    chrome.runtime.sendMessage({
      type: EventOpenTab,
      url: chrome.runtime.getURL('option/index.html'),
    });
  });

  const updateSearchResult = (items) => {
    items.forEach((i) => {
      const element = document.querySelector(`a[href="${i.url}"]`)
      if (element) {
        const img = document.createElement('img');
        img.src = logoUrl;
        img.style.width = '16px';
        element.parentNode.insertBefore(img, element);
      }
    });
  };

  const search = async tokens => {
    const result = await doSearch(tokens, {
      itemType: queryInfo.itemType,
      before: queryInfo.before,
      after: queryInfo.after,
      tag: queryInfo.tag
    });
    app.ports.searchResult.send([queryInfo.query, result]);
    updateSearchResult(result);
  };

  app.ports.tokenizeResult.subscribe(search);

  if (findIndex(x => x === queryInfo.query, blockList) === -1) {
    app.ports.tokenizeNGram.send(queryInfo.query);
  }
})();

['https://fonts.googleapis.com/css?family=Montserrat',
  'https://fonts.googleapis.com/css?family=Anton',
].forEach(url => {
  const link = document.createElement('link');
  link.href = url;
  document.body.appendChild(link);
});

const style = document.createElement('style');
style.innerHTML = [
  '#chick-list::-webkit-scrollbar{width:2px;}',
  '#chick-list::-webkit-scrollbar-track{background:#FFF;}',
  '#chick-list::-webkit-scrollbar-thumb{background:#CCC;}',
].join('');
style.type = 'text/css';
document.body.appendChild(style);