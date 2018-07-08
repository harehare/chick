import uuid5 from "uuid/v5";
import {
  isEmpty,
  pick,
  assoc,
  splitEvery
} from "ramda";
import {
  getLocalStorage,
  setLocalStorage
} from "Common/chrome";
import {
  sleep
} from 'Common/utils'

const create = items => {
  return new Promise(async resolve => {
    for (const i of items) {
      const {
        url,
        title,
        words,
        snippet,
        lastVisitTime
      } = i;
      if (!words) {
        continue;
      }
      const id = uuid5(url, uuid5.URL);
      const data = await getLocalStorage(id);

      if (!isEmpty(data)) {
        resolve(false);
      }

      await setLocalStorage({
        [id]: {
          url,
          title,
          snippet,
          lastVisitTime
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
    if (!item.title) {
      resolve(false);
      return;
    }
    const url = await getLocalStorage(uuid5(item.url, uuid5.URL));
    if (!isEmpty(url)) {
      console.log('exist index');
      resolve(false)
      return;
    }
    item.lastVisitTime = parseInt(item.lastVisitTime) || null;
    app.ports.createItem.send(pick(['url', 'title', 'lastVisitTime'], item));
    resolve(true);
  });
};

const createIndexWithApi = async (app, url, items) => {
  return new Promise(async resolve => {
    const targetItems = items.filter(async v => {
      const url = await getLocalStorage(uuid5(v.url, uuid5.URL));
      if (!isEmpty(url)) {
        return false;
      }
      if (v.title) {
        return true;
      }
      return false;
    });

    if (isEmpty(targetItems)) {
      console.log('exist index');
      resolve(false);
    }
    for (const items of splitEvery(10, targetItems)) {
      console.log("indexed");
      app.ports.createItemWithApi.send([url, items.map(v => assoc('lastVisitTime', v.lastVisitTime ? Math.round(v.lastVisitTime) : null, v))]);
      await sleep(1000);
    }
    resolve(true);
  });
};

export {
  create,
  createIndex,
  createIndexWithApi
};