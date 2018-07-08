import Elm from '../elm/Main.elm';
import {
  concat,
  filter,
  findIndex,
  map,
  sum,
  prop,
  assoc
} from 'ramda';
import {
  getLocalStorage,
  getSyncStorage
} from 'Common/chrome';
import {
  getOption,
  documentCount
} from 'Common/option';
import queryString from 'query-string';
import moment from 'moment';
import escapeHtml from 'escape-html';

const div = document.createElement('div');
document.body.appendChild(div);

['https://fonts.googleapis.com/css?family=Raleway',
  'https://fonts.googleapis.com/css?family=Anton'
].forEach(url => {
  const link = document.createElement('link');
  link.href = url
  document.body.appendChild(link)
});

const style = document.createElement('style');
style.innerHTML = ["#chick-list::-webkit-scrollbar{width:2px;}",
  "#chick-list::-webkit-scrollbar-track{background: #FFF;}",
  "#chick-list::-webkit-scrollbar-thumb{background:#CCC}"
].join("")
style.type = "text/css";
document.body.appendChild(style);


(async () => {
  const option = await getSyncStorage('option');
  const {
    viewOption,
    blockList,
    position,
    advancedOption
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

  const app = Elm.Main.embed(div, {
    items: [],
    visible: true,
    top: position.top,
    right: position.right,
    query: ''
  });

  const parsed = queryString.parse(location.search)
  const parsedQuery = escapeHtml(parsed.q);

  if (!parsedQuery) {
    return;
  }

  const query = escapeHtml(parsedQuery);

  const search = async (tokens) => {
    const itemIds = await getLocalStorage(tokens);
    const {
      scoringApi
    } = advancedOption;

    if (scoringApi.verify) {
      const ids = Object.values(itemIds).reduce((arr, v) => {
        v.forEach(vv => {
          arr[vv] = 1;
        });
        return arr;
      }, {});
      const index = await getLocalStorage(ids);
      app.ports.scoreResult.subscribe(score => {
        const scoreMap = score.map(v => ({
          [`${v.url}#${v.word}`]: v.score
        }));
        app.ports.searchResult.send([query, Object.keys(index).sort((a, b) => {
          const aa = scoreMap[`${index[a].url}#${index[a].word}`];
          const bb = scoreMap[`${index[a].url}#${index[b].word}`];
          const aScore = aa ? aa : 0
          const bScore = bb ? bb : 0
          return aScore > bScore ? -1 : aScore === bScore ? 0 : 1;
        }).map(v => assoc('history', !!index[v].lastVisitTime, index[v]))]);
      });

      const urls = Object.values(index).map(v => v.url).filter(v => v.startsWith('http'));
      app.ports.scoring.send({
        apiUrl: scoringApi.url,
        urls,
        tokens
      });

    } else {
      const searchResult = calcScore(itemIds, documentCount());
      const index = await getLocalStorage(Object.keys(searchResult));

      app.ports.searchResult.send([query, Object.keys(index).sort((a, b) => {
        const aScore = calcTitleScore(tokens, index[a]) * searchResult[a];
        const bScore = calcTitleScore(tokens, index[b]) * searchResult[b];
        return aScore > bScore ? -1 : searchResult[a] < searchResult[b] ? 1 : 0;
      }).map(v =>
        assoc('history', !!index[v].lastVisitTime, index[v]))]);
      deleteIndex(tokens, getOldindex(index));
    }
  };

  app.ports.tokenizeResult.subscribe(search);
  app.ports.queryParseResult.subscribe(search);

  if (findIndex(x => x == parsedQuery, blockList) == -1) {
    const {
      queryParseApi
    } = advancedOption;
    if (queryParseApi.verify) {
      app.ports.queryParse.send([queryParseApi.url, escapeHtml(parsedQuery)]);
    } else {
      app.ports.tokenizeNGram.send(escapeHtml(parsedQuery));
    }
  }

})();

const getOldindex = (index) => {
  const day = moment().add(-2, 'weeks');
  return filter(x => prop('lastVisitTime', x) && x.lastVisitTime < day, index);
}

const deleteIndex = async (tokens, indexes) => {
  chrome.storage.local.remove(Object.values(map(x => x.url, indexes)));
  chrome.storage.local.remove(Object.keys(indexes));
  return map(x => filter(xx => x in ids), tokens);
}

const calcScore = (searchResult, documentCount) => {
  const values = map(v => ({
    score: Math.log(documentCount / v.length),
    ids: v
  }), searchResult);
  return Object.values(values).reduce((arr, v) => {
    v.ids.forEach(id => {
      arr[id] = (id in arr ? arr[id] + 1 : 1) * v.score;
    });
    return arr;
  }, {});
};

const calcTitleScore = (tokens, document) => {
  const totalCount = tokens.length;
  const text = document.title + document.snippet;
  const lastVisitTime = prop('lastVisitTime', document)
  const score = parseFloat(sum(map(v => text.indexOf(v) >= 0 ? 2 : lastVisitTime ? 1.2 : 0, tokens))) / parseFloat(totalCount);
  return score * score;
}