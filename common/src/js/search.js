import {
  filter,
  map,
  sum,
  prop,
  assoc,
  take
} from 'ramda';
import moment from 'moment';
import {
  getLocalStorage
} from 'Common/chrome';
import {
  EventGetScore
} from 'Common/constants';

const search = (tokens, useScore = true, since = null) => {
  return new Promise(async (resolve) => {
    const itemIds = await getLocalStorage(tokens);
    const searchResult = filterResult(tokens, itemIds);
    const index = await getLocalStorage(Object.keys(searchResult));

    const doSearch = (url2score = {}) => {
      const tokenLen = tokens.length;
      resolve(Object.keys(index).sort((a, b) => {
        const aScore = (searchResult[a] / tokenLen) * (url2score[index[a].url] || 1.0) * calcScore(tokens, index[a]);
        const bScore = (searchResult[b] / tokenLen) * (url2score[index[b].url] || 1.0) * calcScore(tokens, index[b]);
        return aScore > bScore ? -1 : searchResult[a] < searchResult[b] ? 1 : 0;
      }).reduce((arr, v) => {
        if (!since || index[v].lastVisitTime > since) {
          arr.push(assoc('bookmark', index[v].bookmark || false, index[v]));
        }
        return arr;
      }, []));
    };

    if (useScore) {
      chrome.runtime.sendMessage({
        urls: take(20, Object.values(index).map(x => x.url)),
        words: tokens,
        type: EventGetScore
      }, (res) => {
        if (!res) console.log('error scoring.');
        const url2score = Object.values(res || []).reduce((arr, v) => {
          arr[v.url] = (arr[v.url] || 0.0) + v.score;
          return arr;
        }, {});
        doSearch(url2score);
      });
    } else {
      doSearch();
    }
    deleteIndex(tokens, getOldindex(index));
  });
};

const getOldindex = (index) => {
  const day = moment().add(-2, 'weeks');
  return filter(x => prop('lastVisitTime', x) && x.lastVisitTime < day, index);
}

const deleteIndex = async (tokens, indexes) => {
  chrome.storage.local.remove(Object.values(map(x => x.url, indexes)));
  chrome.storage.local.remove(Object.keys(indexes));
  return map(x => filter(xx => x in ids), tokens);
}

const filterResult = (tokens, searchResult) => {
  return filter(x => x >= tokens.length, Object.values(searchResult).reduce((arr, v) => {
    v.forEach(id => {
      arr[id] = id in arr ? arr[id] + 1 : 1;
    });
    return arr;
  }, {}));
};

const calcScore = (tokens, document) => {
  const text = (document.title + document.snippet).toLowerCase();
  const lastVisitTime = prop('lastVisitTime', document);
  return parseFloat(sum(map(v => document.bookmark ? 100.0 : text.indexOf(v) >= 0 ? 10.0 : !lastVisitTime ? 5.0 : 2.5, tokens)));
}

export {
  search,
  getOldindex,
  deleteIndex
}