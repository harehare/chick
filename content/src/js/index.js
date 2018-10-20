import Elm from '../elm/Main.elm';
import {
  findIndex,
  isEmpty,
  uniq,
  omit,
  equals
} from 'ramda';
import {
  getSyncStorage,
  setSyncStorage
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
import parse from 'url-parse';

const div = document.createElement('div');
document.body.appendChild(div);

const searchEngineInfo = {
  google: {
    id: 'lst-ib',
    url: 'https://google',
    itemClass: 'g'
  },
  duckDuckGo: {
    id: 'search_form_input',
    url: 'https://duckduckgo.com'
  },
  bing: {
    id: 'sb_form_q',
    url: 'https://bing.com'
  },
  yahoo: {
    id: 'yschsp',
    url: 'https://search.yahoo.co.jp'
  }
};

const showBlockLink = (itemClass) => {
  const items = document.querySelectorAll(`.${itemClass}`);
  items.forEach(item => {
    const a = document.createElement("a");
    const link = item.querySelector('a');
    a.className = 'block-url';
    if (link) {
      const url = parse(link.href);
      a.innerHTML = `Block ${url.hostname}`;
      a.onclick = async () => {
        const option = getOption(await getSyncStorage('option'));
        option.blockDomains.push(url.hostname);
        chrome.storage.sync.set({
          'option': omit(['blockKeyword', 'isIndexing', 'logoUrl'], option)
        });
        item.remove();
      }
    };
    item.appendChild(a);
  });
};

const blockSearchResult = async (itemClass) => {
  const items = document.querySelectorAll(`.${itemClass}`);
  const option = getOption(await getSyncStorage('option'));
  const {
    blockDomains
  } = option;
  items.forEach(item => {
    const link = item.querySelector('a');
    if (link) {
      const url = parse(link.href);
      if (findIndex(equals(url.hostname), blockDomains) !== -1) {
        item.remove();
      }
    }
  });
};

(async () => {
  const option = await getSyncStorage('option');
  const {
    viewOption,
    blockList,
  } = getOption(option);

  const info = Object.entries(searchEngineInfo).reduce((arr, [k, v]) => {
    const currentUrl = location.href.replace('www\.', '');
    if (viewOption[k] && currentUrl.startsWith(v.url)) {
      arr.id = v.id;
      arr.itemClass = v.itemClass;
    }
    if (!viewOption[k] && currentUrl.startsWith(v.url)) {
      arr.hide = true;
    }
    return arr;
  }, {});

  if (info.hide) {
    return;
  }

  const searchInput = document.querySelector(`#${info.id}`);
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

  const search = async tokens => {
    const result = await doSearch(tokens, {
      itemType: queryInfo.itemType,
      before: queryInfo.before,
      after: queryInfo.after,
      tag: queryInfo.tag
    });
    app.ports.searchResult.send([queryInfo.query, result]);
  };

  app.ports.tokenizeResult.subscribe(search);

  if (findIndex(equals(queryInfo.query), blockList) === -1) {
    app.ports.tokenizeNGram.send(queryInfo.query);
  }

  if (searchInput !== null) {
    searchInput.addEventListener('input', e => {
      const queryInfo = queryParser(e.target.value);
      if (findIndex(equals(queryInfo.query), blockList) === -1) {
        app.ports.tokenizeNGram.send(queryInfo.query);
      }
    });
  }
  blockSearchResult(info.itemClass);
  showBlockLink(info.itemClass);
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
  '.block-url{cursor:pointer;color:#1a0dab;}',
].join('');
style.type = 'text/css';
document.body.appendChild(style);