import {
  isEmpty
} from 'ramda';

const getOption = data => {
  if (!data.option || isEmpty(data.option)) {
    data.option = {
      viewOption: {
        google: true,
        bing: true,
        duckDuckGo: true,
        yahoo: true
      },
      blockList: [],
      blockKeyword: '',
      query: '',
      searchResult: [],
      deleteUrlList: [],
      indexInfo: [],
      indexTarget: {
        bookmark: true,
        history: true
      },
      changed: false,
      isIndexing: false,
      status: {
        indexedCount: 0,
        documentCount: 0
      },
      advancedOption: {
        scrapingApi: {
          url: '',
          verify: false
        },
        queryParseApi: {
          url: '',
          verify: false
        },
        scoringApi: {
          url: '',
          verify: false
        }
      }
    }
  } else {
    Object.assign(data.option, {
      changed: false,
      blockKeyword: '',
      query: '',
      searchResult: [],
      deleteUrlList: [],
      isIndexing: localStorage.getItem('suspend_indexing') === 'true',
      indexInfo: []
    });

    if (!data.status) {
      data.status = {
        indexedCount: 0,
        documentCount: 0
      }
    }
  }
  return data.option;
};

const documentCount = () => {
  return localStorage.length - 2;
};

const setIndexedUrl = (url) => {
  localStorage.setItem(`indexed:${url}`, '1');
};

const hasIndex = (url) => {
  return !!localStorage.getItem(`indexed:${url}`);
}

const deleteIndexedStatus = () => {
  Object.keys(localStorage).forEach(v => {
    if (v.startsWith('indexed:')) {
      localStorage.removeItem(v);
    }
  });
};

const indexingStatus = () => {
  const status = localStorage.getItem('suspend_indexing');
  return status === 'true';
}

const setIndexingStatus = (status) => {
  localStorage.setItem('suspend_indexing', status);
}

const suspendIndexing = () => {
  localStorage.setItem('suspend_indexing', true);
}

const resumeIndexing = () => {
  localStorage.setItem('suspend_indexing', false);
}

export {
  getOption,
  hasIndex,
  documentCount,
  setIndexedUrl,
  deleteIndexedStatus,
  indexingStatus,
  setIndexingStatus,
  suspendIndexing,
  resumeIndexing,
};