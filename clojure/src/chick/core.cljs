(ns chick.core
  (:require
   [chick.index :as index]
   [chick.import :as importer])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(.. js/chrome -runtime -onMessage (addListener
                                   (fn [request sender sendResponse]
                                     (cond
                                       (= request.type "IMPORT_POCKET")
                                       (index/start-index)
                                       (= request.type "IMPORT_INDEX")
                                       (importer/import-index request.data))
                                     true)))

(.. js/document (addEventListener "addIndex" (fn [e]
                                               (let [url (.. e -detail -url)
                                                     words (.. e -detail -words)]
                                                 (add-word words url)))))