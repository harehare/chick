(ns chick.import
  (:require [clojure.string :as str]))

(defn import-index [data]
  (let [items (map (fn [row] (let [tokens (str/split row #"\t")
                                   url (first tokens)
                                   item-type (second tokens)]
                               {:title "" :url url :item-type item-type})) (str/split data #"\n"))]
    (.dispatchEvent js/document (new js/CustomEvent "fullIndex" (clj->js {:detail {:items items}})))))

(defn start-import [data]
  (try
    (import-index data)
    (catch Exception ex
    ; TODO: error notify
      (.printStackTrace ex))))