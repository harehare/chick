(ns chick.cache)

(defonce cache (atom {}))

(defn lookup [item]
  (get @cache item))

(defn has? [item]
  (contains? @cache item))

(defn add [item value]
  (swap! cache (keyword item) value))