import Elm from '../elm/Main.elm';
import {
  findIndex,
  assoc,
  isEmpty
} from 'ramda';
import {
  getLocalStorage,
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

const div = document.createElement('div');
document.body.appendChild(div);

(async () => {
  const option = await getSyncStorage('option');
  const {
    viewOption,
    blockList,
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

  const app = Elm.Main.embed(div);
  const parsedQuery = queryString.parse(location.search).q || queryString.parse(location.search).p;

  app.ports.imageUrl.send(chrome.runtime.getURL('img/logo.png'));
  app.ports.changeVisiblety.send(!localStorage.getItem('visible') || localStorage.getItem('visible') === 'true');

  if (isEmpty(parsedQuery)) {
    return;
  }

  const queryInfo = queryParser(parsedQuery);

  app.ports.setVisiblety.subscribe(visible => {
    localStorage.setItem('visible', visible);
  });

  const search = async tokens => {
    const itemIds = await getLocalStorage(tokens);
    const {
      scoringApi
    } = advancedOption;

    if (scoringApi.verify) {
      // TODO: itemType
      const ids = Object.values(itemIds).reduce((arr, v) => {
        v.forEach(vv => {
          arr[vv] = 1;
        });
        return arr;
      }, {});
      const index = await getLocalStorage(ids);
      app.ports.scoreResult.subscribe(score => {
        const scoreMap = score.reduce((arr, v) => {
          arr[v.url] = (arr[v.url] || 1.0) + v.score;
          return arr;
        }, {});
        app.ports.searchResult.send([
          parsedQuery,
          Object.keys(index)
          .sort((a, b) => {
            const aa = scoreMap[index[a].url];
            const bb = scoreMap[index[b].url];
            const aScore = aa ? aa : 0;
            const bScore = bb ? bb : 0;
            return aScore > bScore ? -1 : aScore === bScore ? 0 : 1;
          })
          .map(v => assoc('bookmark', index[v].bookmark || false, index[v]))
        ]);
        app.ports.show.send(0);
      });

      const urls = Object.values(index)
        .map(v => v.url)
        .filter(v => v.startsWith('http'));
      app.ports.scoring.send({
        apiUrl: scoringApi.url,
        urls,
        tokens
      });
    } else {
      app.ports.searchResult.send([queryInfo.query, await doSearch(tokens, true, {
        itemType: queryInfo.itemType,
        since: null
      })]);
      app.ports.show.send(0);
    }
  };

  app.ports.tokenizeResult.subscribe(search);
  app.ports.queryParseResult.subscribe(search);

  if (findIndex(x => x === queryInfo.query, blockList) === -1) {
    const {
      queryParseApi
    } = advancedOption;
    if (queryParseApi.verify) {
      app.ports.queryParse.send([queryParseApi.url, queryInfo.query]);
    } else {
      app.ports.tokenizeNGram.send(queryInfo.query);
    }
  }
})();

['https://fonts.googleapis.com/css?family=Montserrat',
  'https://fonts.googleapis.com/css?family=Anton'
].forEach(url => {
  const link = document.createElement('link');
  link.href = url;
  document.body.appendChild(link);
});

const style = document.createElement('style');
style.innerHTML = [
  '#chick-list::-webkit-scrollbar{width:2px;}',
  '#chick-list::-webkit-scrollbar-track{background: #FFF;}',
  '#chick-list::-webkit-scrollbar-thumb{background:#CCC}'
].join('');
style.type = 'text/css';
document.body.appendChild(style);