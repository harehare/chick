import uuid5 from "uuid/v5";
import {
  isEmpty,
  pick,
} from "ramda";
import {
  getLocalStorage,
  setLocalStorage,
  getSyncStorage
} from "Common/chrome";
import {
  getOption,
  setIndexedUrl
} from 'Common/option'

const create = items => {
  return new Promise(async resolve => {
    for (const item of items) {
      const {
        url,
        title,
        words,
        snippet,
        createdAt,
        itemType
      } = item;
      if (isEmpty(words) || isEmpty(itemType)) {
        continue;
      }
      const id = uuid5(url, uuid5.URL);

      setIndexedUrl(url, words);
      document.dispatchEvent(new CustomEvent("addIndex", {
        detail: {
          url,
          words
        }
      }));

      document.dispatchEvent(new CustomEvent('addTrainData', {
        detail: {
          items: [{
            label: id,
            words
          }],
          callback: () => {
            console.log('add train');
          }
        }
      }));

      const data = await getLocalStorage(id);

      if (!isEmpty(data)) {
        resolve(false);
      }

      await setLocalStorage({
        [id]: {
          url,
          title,
          snippet,
          createdAt,
          itemType,
          bookmark: itemType === 'bookmark',
          tags: []
        }
      });

      const currentIndex = await getLocalStorage(words);
      const index = words.reduce((arr, x) => {
        if (currentIndex[x] && !isEmpty(currentIndex[x])) {
          currentIndex[x].push(id);
          arr[x] = currentIndex[x];
        } else {
          arr[x] = [id];
        }
        return arr;
      }, {});
      await setLocalStorage(index);
    }
    resolve(true);
  });
};

const createIndex = (app, item) => {
  return new Promise(async resolve => {
    const url = await getLocalStorage(uuid5(item.url, uuid5.URL));

    if (!isEmpty(url)) {
      console.log('exist index');
      resolve(false)
      return;
    }
    item.createdAt = parseInt(item.createdAt) || null;

    const indexItem = pick(['url', 'title', 'createdAt', 'itemType'], item);

    if (isEmpty(indexItem.url)) {
      resolve(false);
      return;
    }

    app.ports.createItem.send(indexItem);
    resolve(true);
  });
};

export {
  create,
  createIndex,
};