import {
  head,
} from 'ramda';


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

export {
  openUrl,
  getLocalStorage,
  getSyncStorage,
  setLocalStorage,
  setSyncStorage,
  sendMessage,
  getVisit
};