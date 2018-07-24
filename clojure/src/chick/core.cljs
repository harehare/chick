(ns chick.core
  (:require [konserve.core :as k]
            [konserve.indexeddb :refer [new-indexeddb-store]]
            [clojure.math.combinatorics :as combo]
            [chick.cache :as cache]
            [cljs.core.async :refer [chan <! close! pipeline]])
  (:require-macros [cljs.core.async.macros :refer [go go-loop]]))

(enable-console-print!)

(defonce word-queue (chan 1024))

(defonce in  (chan 1024))

(defonce out (chan 1024))

(go (def idf-db (<! (new-indexeddb-store "idf")))
    (println (str "create idf db"))
    (when-not (<! (k/exists? idf-db "total"))
      (<! (k/assoc-in idf-db ["total"] {:cnt 0}))))

(go (def tf-db (<! (new-indexeddb-store "tf")))
    (println (str "create tf db")))

(defn add-word-tf
  [words url]
  (go (let [exists? (<! (k/exists? tf-db url))]
        (if exists?
          ((doseq [word words]
             (<! (k/update-in tf-db [url (keyword word)] inc)))
           (<! (k/update-in tf-db [url :total] inc)))
          (<! (k/assoc-in tf-db [url] (merge {:total 1} (into {} (for [k words] [(keyword k) 1])))))))))

(defn add-word-idf
  [words]
  (go (let [update (atom [])
            insert (atom [])]
        (doseq [word words]
          (let [exists? (<! (k/exists? idf-db word))]
            (if exists?
              (swap! update conj word)
              (swap! insert conj word))))
        (doseq [word @update]
          (<! (k/update-in idf-db [word :cnt] inc)))
        (println (str "add words " (count @insert)))
        (doseq [word @insert]
          (<! (k/assoc-in idf-db [word] {:cnt 1}))))))

(defn tf-idf
  [word-num word-all doc-all doc-num]
  (* (/ word-num word-all) (Math/log (/ doc-all doc-num))))

(defn get-score
  [urls words cb]
  (go (time (let [doc-all (if (cache/has? "idf-total") (cache/get "idf-total") (<! (k/get-in idf-db ["total" :cnt])))
                  items (combo/cartesian-product urls words)
                  result (atom [])]
              (doseq [x items]
                (let [url (first x)
                      word (second x)]
                  (>! in {:url url :word word :doc-all doc-all})))
              (doseq [_ items]
                (swap! result conj (<! out)))
              (cb (clj->js @result))))))

(pipeline
 10
 (doto (chan) (close!))
 (map (fn [m] (go (let [{:keys [url word doc-all]} m
                        total-key (str url "-total")]
                    (if-let [word-num (if (cache/has? url) (cache/get url) (<! (k/get-in tf-db [url (keyword word)])))]
                      (let [doc-num (if (cache/has? word) (cache/get word) (<! (k/get-in idf-db [word :cnt])))
                            word-all (if (cache/has? total-key) (cache/get (str url "-total")) (<! (k/get-in tf-db [url :total])))]
                        (cache/add url word-num)
                        (cache/add word doc-num)
                        (cache/add total-key word-all)
                        (>! out {:url url :score (tf-idf word-num word-all doc-all doc-num)}))
                      (>! out {:url "" :score 0.0}))))))
 in
 false)

(pipeline
 4
 (doto (chan) (close!))
 (map (fn [words] (add-word-idf words) true))
 word-queue
 false)

(.. js/chrome -runtime -onMessage (addListener
                                   (fn [request sender sendResponse]
                                     (when (= request.type "GET_SCORE")
                                       (get-score request.urls request.words sendResponse))
                                     true)))

(.. js/document (addEventListener "addIndex" (fn [e]
                                               (let [url (.. e -detail -url)
                                                     words (.. e -detail -words)]
                                                 (go (<! (k/update-in idf-db ["total" :cnt] inc)))
                                                 (add-word-tf words url)
                                                 (go (>! word-queue words))))))
