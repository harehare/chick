import {
  filter,
  map,
  sum,
  prop,
  pipe,
  assoc,
  head,
  cond,
  startsWith,
  T,
  groupBy,
  contains
} from 'ramda';
import moment from 'moment';
import {
  getLocalStorage,
  sendMessage
} from 'Common/chrome';
import {
  EventGetScore
} from 'Common/constants';

const queryParser = (query) => {
  const tokens = query.split(' ').map(x => cond([
    [startsWith('type:'), t => ({
      itemType: t.split(':')[1]
    })],
    [startsWith('before:'), t => ({
      before: moment(t.split(':')[1]).valueOf()
    })],
    [startsWith('after:'), t => ({
      after: moment(t.split(':')[1]).valueOf()
    })],
    [startsWith('#'), t => ({
      tag: t.split('#')[1]
    })],
    [T, t => ({
      query: t
    })],
  ])(x));

  return Object.entries(groupBy((token) => head(Object.keys(token)), tokens)).reduce((arr, [k, v]) => {
    arr[k] = v.reduce(((arr, x) => {
      return arr + ' ' + Object.values(x).join(' ');
    }), "").trim();
    return arr;
  }, {});
};

const search = (tokens, useScore = true, filters = {
  before: null,
  after: null,
  itemType: null,
  tag: null
}) => {
  return new Promise(async (resolve) => {
    const itemIds = await getLocalStorage(tokens);
    const searchResult = filterResult(tokens, itemIds);
    const index = await getLocalStorage(Object.keys(searchResult));

    const doSearch = (url2score = {}) => {
      const tokenNum = tokens.length;
      resolve(Object.keys(index).sort((a, b) => {
        const aScore = (searchResult[a] / tokenNum) * (url2score[index[a].url] || 1.0) * calcScore(tokens, index[a]);
        const bScore = (searchResult[b] / tokenNum) * (url2score[index[b].url] || 1.0) * calcScore(tokens, index[b]);
        return aScore > bScore ? -1 : searchResult[a] < searchResult[b] ? 1 : 0;
      }).reduce((arr, v) => {
        if ((!filters.before || index[v].createdAt <= filters.before) &&
          (!filters.after || index[v].createdAt >= filters.after) &&
          (!filters.itemType || index[v].itemType === filters.itemType) &&
          (!filters.tag || contains(filters.tag, index[v].tags))) {
          arr.push(
            pipe(
              assoc('bookmark', index[v].bookmark || false),
              assoc('tags', index[v].tags || []))(index[v]));
        }
        return arr;
      }, []));
    };

    if (useScore) {
      const res = await sendMessage({
        urls: Object.values(index).map(x => x.url),
        words: tokens,
        type: EventGetScore
      });
      if (!res) console.log('error scoring.');
      const url2score = Object.values(res || []).reduce((arr, v) => {
        arr[v.url] = (arr[v.url] || 0.0) + v.score;
        return arr;
      }, {});
      doSearch(url2score);
    } else {
      doSearch();
    }
    deleteIndex(tokens, getOldindex(index));
  });
};

const getOldindex = (index) => {
  const day = moment().add(-4, 'weeks');
  return filter(x => prop('createdAt', x) && x.itemType === 'history' && x.createdAt < day, index);
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
  return parseFloat(sum(map(v => text.indexOf(v) >= 0 ? 10.0 : 1.0, tokens)));
}

export {
  search,
  queryParser,
  getOldindex,
  deleteIndex
}