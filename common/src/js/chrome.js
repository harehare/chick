import {
  head,
} from 'ramda';
import uuid4 from "uuid/v4";


function sendMessage(message) {
  return new Promise((resolve, reject) => {
    chrome.runtime.sendMessage(message, res => {
      const err = chrome.runtime.lastError;
      if (err) {
        reject(err);
      } else {
        resolve(res);
      }
    });
  });
}

function getVisit(url) {
  return new Promise((resolve, reject) => {
    chrome.history.getVisits({
      url
    }, res => {
      const err = chrome.runtime.lastError;
      if (err) {
        reject(err);
      } else if (res.length > 0) {
        resolve(head(res));
      } else {
        resolve({});
      }
    });
  });
}

function getStorage(keys, fun) {
  return new Promise((resolve, reject) => {
    fun.get(keys, items => {
      const err = chrome.runtime.lastError;
      if (err) {
        reject(err);
      } else {
        resolve(items);
      }
    });
  });
}

function setStorage(items, fun) {
  return new Promise((resolve, reject) => {
    fun.set(items, () => {
      const err = chrome.runtime.lastError;
      if (err) {
        reject();
      } else {
        resolve();
      }
    });
  });
}

function getLocalStorage(keys) {
  return getStorage(keys, chrome.storage.local);
}

function getSyncStorage(keys) {
  return getStorage(keys, chrome.storage.sync);
}

function setLocalStorage(items) {
  return setStorage(items, chrome.storage.local);
}

function setSyncStorage(items) {
  return setStorage(items, chrome.storage.sync);
}

function openUrl(url, active = false) {
  chrome.tabs.create({
    url,
    active
  });
}

function showNotification(title, message) {
  const options = {
    iconUrl: chrome.runtime.getURL('img/logo.png'),
    type: 'basic',
    title,
    message,
    priority: 1,
  };
  chrome.notifications.create(uuid4(), options);
}

export {
  openUrl,
  getLocalStorage,
  getSyncStorage,
  setLocalStorage,
  setSyncStorage,
  sendMessage,
  getVisit,
  showNotification
};