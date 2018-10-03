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
  assoc,
  pipe
} from 'ramda';
import camelcasekeys from 'camelcase-keys';
import escapeHtml from 'escape-html';
import moment from 'moment';
import {
  openUrl,
  getLocalStorage,
  getSyncStorage,
  getVisit
} from 'Common/chrome';
import uuid5 from "uuid/v5";
import {
  getOption,
  resumeIndexing,
  indexingStatus,
  setIndexedUrl,
  hasIndex,
  documentCount,
  totalDocumentCount,
  setDocumentCount,
  getIndexedInfo,
  indexedList
} from 'Common/option';
import {
  EventIndexing,
  EventReIndexing,
  EventErrorIndexing,
  EventOpenTab,
  EventImportBookmark,
  EventImportHistory,
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
import setupWasm from 'Wasm/wasm_exec';

const app = Elm.BackGround.worker();
const IndexParallel = 4;
const enabledWasm = false;

const startWasm = async () => {
  if (!enabledWasm) {
    return;
  }

  setupWasm();
  if (!WebAssembly.instantiateStreaming) {
    WebAssembly.instantiateStreaming = async (resp, importObject) => {
      const source = await (await resp).arrayBuffer();
      return await WebAssembly.instantiate(source, importObject);
    };
  }
  const go = new Go();
  let mod, inst;
  WebAssembly.instantiateStreaming(fetch(chrome.runtime.getURL('wasm/bin/lib.wasm')), go.importObject).then(async (result) => {
    mod = result.module;
    inst = result.instance;
    (async () => {
      await go.run(inst);
      inst = await WebAssembly.instantiate(mod, go.importObject);
    })();

    const list = indexedList();
    if (list.length > 0) {
      for (const index of splitEvery(Math.ceil(list.length / IndexParallel), list)) {
        document.dispatchEvent(new CustomEvent('addTrainData', {
          detail: {
            items: index,
            callback: () => {
              console.log('wasm', 'Add train data');
            }
          }
        }));
      }
    }

  }).catch((err) => {
    console.error(err);
  });
}

const getBookmark = (bookmarks) => {
  if (!bookmarks) return [];
  return [...bookmarks.reduce((arr, v) => {
    if (v.url) {
      const dateAdded = v.dateAdded ? v.dateAdded : moment().valueOf();
      arr.push(pipe(assoc('itemType', 'bookmark'), assoc('createdAt', dateAdded))(pick(['url', 'title'], v)));
    }
    return arr;
  }, []), ...flatten(bookmarks.reduce((arr, v) => {
    if (v.children) {
      arr.push(getBookmark(v.children));
    }
    return arr;
  }, []))];
}

const fullIndex = async (docs) => {

  if (isEmpty(docs)) {
    console.log('document is indexed all.');
    return;
  }

  const importDocs = docs.filter(doc => !hasIndex(doc.url));
  setDocumentCount(totalDocumentCount() + importDocs.length);

  const totalCount = totalDocumentCount();
  let currentCount = documentCount() + 1;

  const indexing = (items) => {
    return new Promise(async resolve => {
      for (const item of items) {
        setIndexedUrl(item.url, {});

        const isIndexed = await createIndex(app, item);

        chrome.runtime.sendMessage({
          type: EventIndexing,
          documentCount: totalCount,
          indexedCount: ++currentCount
        });

        if (!isIndexed) continue;

        while (indexingStatus()) {
          await sleep(1000);
          console.log('indexing suspend');
        }
      }
      resolve();
    });
  };

  await Promise.all(splitEvery(importDocs.length / IndexParallel, importDocs).map(v => indexing(v)));

  chrome.runtime.sendMessage({
    type: EventIndexing,
    documentCount: documentCount(),
    indexedCount: documentCount()
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
  setIndexedUrl(item.url, {});
}

const importBookmark = async () => {
  const option = getOption(await getSyncStorage('option'));
  localStorage.setItem('indexing_complete', false);
  chrome.bookmarks.getTree(async (tree) => {
    if (head(tree).children) {
      const bookmarks = getBookmark(head(tree).children);
      const userBlockList = option.blockList
      const docs = bookmarks.filter(b => (!hasIndex(b.url) && findIndex(w => b.url.indexOf(w) != -1, [...BlockList, ...userBlockList]) === -1));
      fullIndex(docs);
    }
  });
  localStorage.setItem('indexing_complete', true);
};

const importHistory = async () => {
  const option = getOption(await getSyncStorage('option'));
  localStorage.setItem('indexing_complete', false);
  chrome.history.search({
    text: "",
    startTime: moment().add(-4, 'weeks').valueOf()
  }, (items) => {
    const userBlockList = option.blockList
    const docs = items.filter(async b =>
      (await getVisit(b.url)).transition != 'form_submit' &&
      b.url.startsWith('http') &&
      (!hasIndex(b.url) &&
        findIndex(w => b.url.indexOf(w) != -1, [...BlockList, ...userBlockList]) === -1));
    fullIndex(docs.map(item => assoc('itemType', 'history', item)));
  });
  localStorage.setItem('indexing_complete', true);
};

chrome.bookmarks.onCreated.addListener(async (_, item) => {
  const option = getOption(await getSyncStorage('option'));
  const enabledBookmark = option.indexTarget.bookmark;
  if (!enabledBookmark) {
    console.log('bookmark is disabled.');
    return;
  }
  itemIndexing(pipe(assoc('createdAt', item.dateAdded), assoc('itemType', 'bookmark'))(item));
});

chrome.history.onVisited.addListener(async (item) => {
  const option = getOption(await getSyncStorage('option'));
  const enabledHistory = option.indexTarget.history;

  if (!enabledHistory) {
    console.log('history is disabled.');
    return;
  }

  const visitItem = await getVisit(item.url)

  if (visitItem.transition === 'form_submit') {
    console.log('form_submit!');
    return;
  }

  itemIndexing(pipe(assoc('createdAt', item.lastVisitTime), assoc('itemType', 'history'))(item));
});

chrome.runtime.onMessage.addListener(async (message) => {
  cond([
    [equals(EventReIndexing), async () => {
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
    }],
    [equals(EventOpenTab), () => (openUrl(message.url, true))],
    [equals(EventImportBookmark), () => (importBookmark())],
    [equals(EventImportHistory), () => (importHistory())],
  ])(message.type);
});

chrome.omnibox.onInputChanged.addListener(async (text, suggest) => {
  const queryInfo = queryParser(text);

  const doSearch = async (tokens) => {
    app.ports.queryResult.unsubscribe(doSearch);
    const searchResult = await search(tokens, false, {
      itemType: queryInfo.itemType,
      before: queryInfo.before,
      after: queryInfo.after,
      tag: queryInfo.tag
    });
    if (!isEmpty(searchResult)) {
      suggest(take(6, searchResult).map(x => ({
        content: x.url,
        description: `<dim>${escapeHtml(x.title)}</dim> - <url>${escapeHtml(x.url)}</url>`
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
    title: 'Search keyword',
    id: 'search',
    contexts: ['selection'],
  });
  chrome.contextMenus.create({
    type: 'normal',
    title: 'Search similar page',
    id: 'similar',
    contexts: ['all'],
  });
  openUrl(chrome.runtime.getURL('option/index.html'), true);
  startWasm();
});

chrome.runtime.onStartup.addListener(async () => {
  startWasm();
})

chrome.contextMenus.onClicked.addListener((info) => {
  cond([
    [equals('search'), () => (openUrl(`${chrome.extension.getURL("option/index.html")}?q=${encodeURIComponent(info.selectionText)}`, true))],
    [equals('similar'), () => {
      document.dispatchEvent(new CustomEvent('fit', {
        detail: {
          k: 10,
          label: info.pageUrl,
          callback: () => {
            const start = +new Date();
            document.dispatchEvent(new CustomEvent('predict', {
              detail: {
                words: getIndexedInfo(info.pageUrl).words,
                label: info.pageUrl,
                callback: (labels) => {
                  // TODO:
                  const end = +new Date();
                  console.log(`predict: ${(end - start)}`);
                  console.log(labels);
                }
              }
            }));
          }
        }
      }));
    }],
  ])(info.menuItemId);
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

document.addEventListener("fullIndex", e => {
  fullIndex(camelcasekeys(e.detail.items));
});