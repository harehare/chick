import {
  T,
  cond,
  equals,
  take,
  pick,
  head,
  flatten,
  isEmpty,
  findIndex,
  splitEvery,
  assoc
} from 'ramda';
import camelcasekeys from 'camelcase-keys';
import escapeHtml from 'escape-html';
import {
  openUrl,
  getLocalStorage,
  getSyncStorage
} from 'Common/chrome';
import uuid5 from "uuid/v5";
import {
  getOption,
  resumeIndexing,
  indexingStatus,
  setIndexedUrl,
  hasIndex
} from 'Common/option';
import {
  EventIndexing,
  EventReIndexing,
  EventErrorIndexing
} from 'Common/constants';
import {
  sleep
} from 'Common/utils';
import {
  search,
  queryParser
} from 'Common/search';
import {
  create,
  createIndex,
} from './search-index';
import Elm from "../elm/BackGround.elm";
import {
  BlockList
} from './blocklist';

const app = Elm.BackGround.worker();
const IndexParallel = 4;

const getBookmark = (bookmarks) => {
  if (!bookmarks) return [];
  return [...bookmarks.reduce((arr, v) => {
    if (v.url) {
      arr.push(assoc('itemType', 'bookmark', pick(['url', 'title'], v)));
    }
    return arr;
  }, []), ...flatten(bookmarks.reduce((arr, v) => {
    if (v.children) {
      arr.push(getBookmark(v.children));
    }
    return arr;
  }, []))];
}

const fullIndex = async (indexDocuments) => {
  let currentCount = 0;
  localStorage.setItem('currentCount', 0);
  const totalCount = indexDocuments.length;

  if (isEmpty(indexDocuments)) {
    console.log('document is indexed all.');
    return;
  }

  const indexing = (items, total) => {
    return new Promise(async resolve => {
      for (const item of items) {
        setIndexedUrl(item.url);
        const isIndexed = await createIndex(app, item);
        if (!isIndexed) continue;
        currentCount++;

        chrome.runtime.sendMessage({
          type: EventIndexing,
          documentCount: total,
          indexedCount: currentCount
        });
        localStorage.setItem('currentCount', currentCount);

        while (indexingStatus()) {
          await sleep(3000);
          console.log('indexing suspend');
        }
      }
      resolve();
    });
  };

  await Promise.all(splitEvery(indexDocuments.length / IndexParallel, indexDocuments).map(v => indexing(v, totalCount)));
  localStorage.setItem('indexingCount', totalCount);

  chrome.runtime.sendMessage({
    type: EventIndexing,
    documentCount: totalCount,
    indexedCount: totalCount
  });

  app.ports.getErrorItems.send(0);
  app.ports.indexAllFromApi.send(0);
  resumeIndexing();
};

const itemIndexing = async (item) => {
  const option = getOption(await getSyncStorage('option'));
  const userBlockList = option.blockList

  console.log('user block list.', userBlockList);
  if (findIndex(v => item.url.indexOf(v) != -1, [...BlockList, ...userBlockList]) != -1) {
    console.log('skip index');
    return
  }

  if (!createIndex(app, item)) return;
  setIndexedUrl(item.url);
}

const startFullIndexing = async () => {
  localStorage.setItem('indexing_complete', false);
  const option = getOption(await getSyncStorage('option'));
  const enabledBookmark = option.indexTarget.bookmark;
  if (enabledBookmark) {
    chrome.bookmarks.getTree(async (tree) => {
      if (head(tree).children) {
        const bookmarks = getBookmark(head(tree).children);
        const userBlockList = option.blockList
        const indexDocuments = bookmarks.filter(b => (!hasIndex(b.url) && findIndex(w => b.url.indexOf(w) != -1, [...BlockList, ...userBlockList]) === -1));
        fullIndex(indexDocuments);
      }
    });
    localStorage.setItem('indexing_complete', true);
  }
};

chrome.bookmarks.onCreated.addListener(async (_, item) => {
  const option = getOption(await getSyncStorage('option'));
  const enabledBookmark = option.indexTarget.bookmark;
  if (!enabledBookmark) {
    console.log('bookmark is disabled.');
    return;
  }
  item.createdAt = item.dateAdded;
  itemIndexing(assoc('itemType', 'bookmark', item));
});

chrome.history.onVisited.addListener(async (item) => {
  const option = getOption(await getSyncStorage('option'));
  const enabledHistory = option.indexTarget.history;

  if (!enabledHistory) {
    console.log('history is disabled.');
    return;
  }
  item.createdAt = item.lastVisitTime;
  itemIndexing(assoc('itemType', 'history', item));
});

chrome.runtime.onMessage.addListener(async (message) => {
  if (message.type === EventReIndexing) {
    console.log('start reindexing...');
    const items = Object.keys(localStorage).reduce((arr, x) => {
      if (x.startsWith('indexed:')) {
        arr.push(uuid5(x.slice(8), uuid5.URL));
        localStorage.removeItem(x);
      }
      return arr;
    }, []);
    const indexedItems = await getLocalStorage(items);
    chrome.storage.local.clear();
    fullIndex(Object.values(indexedItems));
  }
});

chrome.omnibox.onInputChanged.addListener(async (text, suggest) => {
  const queryInfo = queryParser(text);

  const doSearch = async (tokens) => {
    app.ports.queryResult.unsubscribe(doSearch);
    const searchResult = await search(tokens, false, {
      itemType: queryInfo.itemType,
      before: queryInfo.before,
      after: queryInfo.after,
    });
    if (!isEmpty(searchResult)) {
      suggest(take(6, searchResult).map(x => ({
        content: x.url,
        description: `<url>${escapeHtml(x.url)}</url> - <dim>${escapeHtml(x.title)}</dim>`
      })).filter(x => !isEmpty(x.content)));
    }
  }

  const setSearchResult = async (items) => {
    app.ports.setSearchResult.unsubscribe(setSearchResult);
    if (!isEmpty(items)) {
      suggest(take(6, items).map(x => ({
        content: x.url,
        description: `<url>${escapeHtml(x.url)}</url> - <dim>${escapeHtml(x.title)}</dim>`
      })).filter(x => !isEmpty(x.content)));
    }
  }

  if (!isEmpty(queryInfo.query)) {
    const option = await getSyncStorage('option');
    const {
      searchApi
    } = getOption(option);

    if (searchApi.verify) {
      app.ports.setSearchResult.subscribe(setSearchResult);
      app.ports.backgroundSearchApi.send([searchApi.url, queryInfo.query]);
    } else {
      app.ports.queryResult.subscribe(doSearch);
      app.ports.getQuery.send(queryInfo.query);
    }
  }
});

chrome.omnibox.onInputEntered.addListener((url, disposition) => {
  cond([
    [() => !url.startsWith('http'), () => (openUrl(chrome.runtime.getURL('option/index.html?q=') + encodeURIComponent(url), true))],
    [equals('newForegroundTab'), () => (openUrl(url, true))],
    [equals('newBackgroundTab'), () => (openUrl(url))],
    [T, () => (
      chrome.tabs.update({
        url: url
      })
    )]
  ])(disposition);
});

chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    type: 'normal',
    title: 'Search',
    id: 'chick',
    contexts: ['selection'],
  });
});

chrome.contextMenus.onClicked.addListener((info) => {
  openUrl(`${chrome.extension.getURL("option/index.html")}?q=${encodeURIComponent(info.selectionText)}`, true);
});

app.ports.indexItem.subscribe(async ({
  url,
  title,
  words,
  snippet,
  createdAt,
  itemType
}) => {
  await create([{
    url,
    title,
    words,
    snippet,
    createdAt,
    itemType
  }]);
  if (isEmpty(url)) {
    return;
  }
  document.dispatchEvent(new CustomEvent("addIndex", {
    detail: {
      url,
      words
    }
  }));
});

app.ports.indexError.subscribe(errorCount => {
  // TODO:
  chrome.runtime.sendMessage({
    type: EventErrorIndexing,
    errorCount
  });
});

app.ports.errorItems.subscribe(async items => {
  for (const item of items) {
    const {
      url,
      title,
      createdAt,
      itemType
    } = item;
    await create([{
      url,
      title,
      words: [],
      snippet: '',
      createdAt,
      itemType
    }]);
  }
});

chrome.runtime.onInstalled.addListener(() => {
  startFullIndexing();
});

chrome.runtime.onStartup.addListener(() => {
  startFullIndexing();
});

document.addEventListener("fullIndex", e => {
  fullIndex(camelcasekeys(e.detail.items));
});