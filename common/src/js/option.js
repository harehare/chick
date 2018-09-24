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
      inputTag: '',
      indexTarget: {
        bookmark: true,
        history: true,
        pocket: false,
      },
      changed: false,
      isIndexing: false,
      status: {
        indexedCount: 0,
        documentCount: 0
      },
      searchApi: {
        url: '',
        verify: false
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
      indexInfo: [],
      inputTag: ''
    });

    if (!data.option.indexTarget.pocket) {
      data.option.indexTarget.pocket = false;
    }

    if (!data.option.searchApi) {
      data.option.searchApi = {
        url: '',
        verify: false
      }
    }

    if (!data.option.status) {
      data.option.status = {
        indexedCount: 0,
        documentCount: 0
      }
    }
  }
  return data.option;
};

const documentCount = () => {
  return Object.keys(localStorage).filter(x => x.startsWith('indexed:')).length;
};

const totalDocumentCount = () => {
  return parseInt(localStorage.getItem('totalCount') ? localStorage.getItem('totalCount') : 0);
};

const setDocumentCount = (count) => {
  localStorage.setItem('totalCount', count);
};

const setIndexedUrl = (url, itemType) => {
  localStorage.setItem(`indexed:${url}`, itemType);
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
  totalDocumentCount,
  setDocumentCount
};