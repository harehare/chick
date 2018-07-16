(ns chick.core
  (:require [konserve.core :as k]
            [konserve.indexeddb :refer [new-indexeddb-store]]
            [clojure.math.combinatorics :as combo]
            [cljs.core.async :refer [chan poll! put! <! timeout]])
  (:require-macros [cljs.core.async.macros :refer [go go-loop]]))

(enable-console-print!)

(def word-queue (chan 1000))

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
        (go (doseq [word @update]
              (<! (k/update-in idf-db [word :cnt] inc))))
        (go
          (println (str "add words " (count @insert)))
          (doseq [word @insert]
            (<! (k/assoc-in idf-db [word] {:cnt 1})))))))

(defn get-score
  [urls words cb]
  (go (time (let [total-doc (<! (k/get-in idf-db ["total" :cnt]))
                  result (atom [])]
              (doseq [x (combo/cartesian-product urls words)]
                (let [url (first x)
                      word (second x)]
                  (when-let [doc-word (<! (k/get-in tf-db [url (keyword word)]))]
                    (let [word-doc (<! (k/get-in idf-db [word :cnt]))
                          doc-all (<! (k/get-in tf-db [url :total]))]
              ; TODO: cache
                      (swap! result conj {:url url :score (* (/ doc-word doc-all) (Math/log (/ total-doc word-doc)))})))))
              (cb (clj->js @result))))))

(go-loop []
  (let [words (<! word-queue)]
    (add-word-idf words))
  (recur))

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
