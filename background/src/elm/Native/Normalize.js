var _harehare$chick$Native_Normalize = (() => {

  function normalize(str) {
    return str.normalize('NFKC');
  }

  return {
    normalize: normalize
  }

})();