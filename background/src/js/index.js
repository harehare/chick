import {
  pick,
  head,
  flatten,
  isEmpty,
  findIndex,
  splitEvery,
} from 'ramda';
import {
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

const fullIndex = () => {
  const getBookmark = (bookmarks) => {
    if (!bookmarks) return [];
    return [...bookmarks.reduce((arr, v) => {
      if (v.url) {
        arr.push(pick(['url', 'title'], v));
      }
      return arr;
    }, []), ...flatten(bookmarks.reduce((arr, v) => {
      if (v.children) {
        arr.push(getBookmark(v.children));
      }
      return arr;
    }, []))];
  }

  const indexing = (items, total) => {
    return new Promise(async resolve => {
      for (const item of items) {
        setIndexedUrl(item.url);
        const isIndexed = await createIndex(app, item);
        if (!isIndexed) continue;
        const count = localStorage.getItem('currentCount');
        const currentCount = (count ? parseInt(count) : 1) + 1;

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
      const count = localStorage.getItem('currentCount');
      const currentCount = (count ? parseInt(count) : 1) + items.length;

      localStorage.setItem('currentCount', currentCount);
      chrome.runtime.sendMessage({
        type: EventIndexing,
        documentCount: total,
        indexedCount: currentCount
      });

      resolve();
    });
  };

  chrome.bookmarks.getTree(async (tree) => {
    if (head(tree).children) {
      const bookmarks = getBookmark(head(tree).children);
      const indexDocuments = bookmarks.filter(v => (!hasIndex(v.url)));
      const option = getOption(await getSyncStorage('option'));
      const scrapingApi = option.advancedOption.scrapingApi;
      const totalCount = indexDocuments.length;

      if (isEmpty(indexDocuments)) {
        console.log('bookmarks is indexed all.');
        return;
      }

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
    }

    resumeIndexing();
    localStorage.setItem('indexing_complete', true);
  });
};

const itemIndexing = async (item) => {
  const option = getOption(await getSyncStorage('option'));
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
    fullIndex();
  }
};

chrome.bookmarks.onCreated.addListener(async (_, item) => {
  const option = getOption(await getSyncStorage('option'));
  const enabledBookmark = option.indexTarget.bookmark;
  if (!enabledBookmark) {
    console.log('bookmark is disabled.');
    return;
  }
  itemIndexing(item);
});

chrome.history.onVisited.addListener(async (item) => {
  console.log('history index');
  const option = getOption(await getSyncStorage('option'));
  const enabledHistory = option.indexTarget.history;
  const userBlockList = option.blockList

  console.log('user block list.', userBlockList);

  if (!enabledHistory) {
    console.log('history is disabled.');
    return;
  }

  if (findIndex(v => item.url.indexOf(v) != -1, [...BlockList, ...userBlockList]) != -1) {
    console.log('skip index');
    return
  }
  itemIndexing(item);
});

chrome.runtime.onMessage.addListener(async (message, sender, sendResponse) => {
  if (message.type === EventReIndexing) {
    chrome.storage.local.clear();
    startFullIndexing();
  }
});

app.ports.indexItem.subscribe(async ({
  url,
  title,
  words,
  snippet,
  lastVisitTime
}) => {
  await create([{
    url,
    title,
    words,
    snippet,
    lastVisitTime
  }]);
});

app.ports.indexItems.subscribe(async items => {
  for (const item of items) {
    const {
      url,
      title,
      words,
      snippet,
      lastVisitTime
    } = item;
    await create([{
      url,
      title: title ? title : snippet,
      words,
      snippet,
      lastVisitTime
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
      lastVisitTime
    } = item;
    await create([{
      url,
      title,
      words: [],
      snippet: '',
      lastVisitTime
    }]);
  }
});

startFullIndexing();