(ns chick.core
  (:require [konserve.core :as k]
            [konserve.indexeddb :refer [new-indexeddb-store]]
            [chick.cache :as cache]
            [cljs.core.async :refer [chan <! close! pipeline]])
  (:require-macros [cljs.core.async.macros :refer [go go-loop]]))

(defonce in  (chan 1024))

(defonce out (chan 1024))

(go (def score-db (<! (new-indexeddb-store "score"))))

(defn add-word
  [words url]
  (go (<! (k/assoc-in score-db [url]
                      (merge {:total (count words)}
                             (->> (group-by (juxt identity count) words)
                                  (into {} (map (fn [[_ value]] [(keyword (first value)) (count value)])))))))))

(defn score
  [word-num word-all]
  (/ word-num word-all))

(defn get-score
  [urls words cb]
  (go (let [result (atom [])
            items (atom [])
            words (js->clj words :keywordize-keys true)]
        (doseq [url urls]
          (when-not (empty? url)
            (swap! items conj url)
            (>! in {:url url :words words})))
        (doseq [_ @items]
          (swap! result conj (<! out)))
        (cb (clj->js @result)))))

(pipeline
 5
 (doto (chan) (close!))
 (map (fn [m] (go (let [{:keys [url words]} m
                        words-info (if (cache/has? url) (cache/get url) (<! (k/get-in score-db [url])))]
                    (cache/add url words-info)
                    (let [word-count (reduce + (map (fn [m] (words-info (keyword m))) words))
                          word-total (words-info :total)]
                      (>! out {:url url :score (score word-count word-total)}))))))
 in
 false)

(.. js/chrome -runtime -onMessage (addListener
                                   (fn [request sender sendResponse]
                                     (when (= request.type "GET_SCORE")
                                       (get-score request.urls request.words sendResponse))
                                     true)))

(.. js/document (addEventListener "addIndex" (fn [e]
                                               (let [url (.. e -detail -url)
                                                     words (.. e -detail -words)]
                                                 (add-word words url)))))
