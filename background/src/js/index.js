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
  getSyncStorage
} from 'Common/chrome';
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
  search
} from 'Common/search';
import {
  create,
  createIndex,
  createIndexWithApi
} from './search-index';
import Elm from "../elm/BackGround.elm";
import {
  BlockList
} from './blocklist';

const app = Elm.BackGround.worker();
const IndexParallel = 2;

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

  const option = getOption(await getSyncStorage('option'));
  const scrapingApi = option.advancedOption.scrapingApi;

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

  const indexingWithApi = (items, total, url) => {
    return new Promise(async resolve => {
      items.forEach(v => {
        setIndexedUrl(v.url);
      });
      const isIndexed = await createIndexWithApi(app, url, items);
      if (!isIndexed) {
        resolve();
        return;
      }
      currentCount++;
      localStorage.setItem('currentCount', currentCount);
      chrome.runtime.sendMessage({
        type: EventIndexing,
        documentCount: total,
        indexedCount: currentCount
      });

      resolve();
    });
  };

  if (scrapingApi.verify) {
    for (const items of splitEvery(10, indexDocuments)) {
      console.log(`request ${scrapingApi.url}`);
      await indexingWithApi(items, totalCount, scrapingApi.url);
      await sleep(5000);
    }
  } else {
    await Promise.all(splitEvery(indexDocuments.length / IndexParallel, indexDocuments).map(v => indexing(v, totalCount)));
  }

  localStorage.setItem('indexingCount', totalCount);
  chrome.runtime.sendMessage({
    type: EventIndexing,
    documentCount: totalCount,
    indexedCount: totalCount
  });

  app.ports.getErrorItems.send(0);
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

  const scrapingApi = option.advancedOption.scrapingApi;
  const isIndexed = await scrapingApi.verify ? createIndexWithApi(app, scrapingApi.url, [item]) : createIndex(app, item);

  if (!isIndexed) return;
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
  itemIndexing(assoc('itemType', 'bookmark', item));
});

chrome.history.onVisited.addListener(async (item) => {
  const option = getOption(await getSyncStorage('option'));
  const enabledHistory = option.indexTarget.history;

  if (!enabledHistory) {
    console.log('history is disabled.');
    return;
  }
  itemIndexing(assoc('itemType', 'history', item));
});

chrome.runtime.onMessage.addListener((message) => {
  if (message.type === EventReIndexing) {
    console.log('start reindexing...');
    chrome.storage.local.clear();
    startFullIndexing();
  }
});

chrome.omnibox.onInputChanged.addListener((text, suggest) => {
  const doSearch = async (tokens) => {
    app.ports.queryResult.unsubscribe(doSearch);
    const searchResult = await search(tokens, false);
    if (!isEmpty(searchResult)) {
      suggest(take(6, searchResult).map(x => ({
        content: x.url,
        description: `<url>${escapeHtml(x.url)}</url> - <dim>${escapeHtml(x.title)}</dim>`
      })).filter(x => !isEmpty(x.content)));
    }
  }
  app.ports.queryResult.subscribe(doSearch);

  if (!isEmpty(text) && text.length > 2) {
    app.ports.getQuery.send(escapeHtml(text));
  }
});

chrome.omnibox.onInputEntered.addListener((url, disposition) => {
  cond([
    [() => !url.startsWith('http'), () => (openUrl(`https://duckduckgo.com/?q=${encodeURIComponent(url)}`))],
    [equals('newForegroundTab'), () => (openUrl(url, true))],
    [equals('newBackgroundTab'), () => (openUrl(url))],
    [T, () => (
      chrome.tabs.update({
        url: url
      })
    )]
  ])(disposition);
});

app.ports.indexItem.subscribe(async ({
  url,
  title,
  words,
  snippet,
  lastVisitTime,
  itemType
}) => {
  await create([{
    url,
    title,
    words,
    snippet,
    lastVisitTime,
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

app.ports.indexItems.subscribe(async items => {
  for (const item of items) {
    const {
      url,
      title,
      words,
      snippet,
      lastVisitTime,
      itemType
    } = item;
    await create([{
      url,
      title: title ? title : snippet,
      words,
      snippet,
      lastVisitTime,
      itemType
    }]);
  }
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
      lastVisitTime,
      itemType
    } = item;
    await create([{
      url,
      title,
      words: [],
      snippet: '',
      lastVisitTime,
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