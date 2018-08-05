(ns chick.pocket
  (:require
   [ajax.core :refer [GET]]))

(def host "https://chick-pocket.herokuapp.com/")

(defn pocket-request-url [redirect-url] (str host "oauth/request?redirect_url=" redirect-url))

(defn pocket-authorize-url [code redirect-url] (str host "oauth/authorize?code=" code "&redirect_url=" redirect-url))

(defn pocket-get-url [access-token] (str host "get?access_token=" access-token))

(def redirect-url (.. js/chrome -identity (getRedirectURL)))

(defn error-handler [{:keys [status status-text]}]
  (.log js/console (str "error: " status " " status-text)))

(defn add-index-handler [response]
  (.dispatchEvent js/document (new js/CustomEvent "fullIndex" (clj->js {:detail {:items response}}))))

(defn get-pocket
  [access-token]
  (GET (pocket-get-url access-token) {:handler add-index-handler
                                      :response-format :json
                                      :keywords? true
                                      :error-handler error-handler}))

(defn authorize-handler [response]
  (get-pocket (response :access_token)))

(defn request-handler [response]
  (.. js/chrome -identity (launchWebAuthFlow (js-obj "url" (response :authorize_url) "interactive" true)
                                             (fn [] (GET (pocket-authorize-url (response :code) redirect-url) {:handler authorize-handler
                                                                                                               :response-format :json
                                                                                                               :keywords? true})))))

(defn start-index
  []
  (GET (pocket-request-url redirect-url) {:handler request-handler
                                          :response-format :json
                                          :keywords? true
                                          :error-handler error-handler}))

; (.. js/chrome -alarms (create "indexing_from_pocket" js-obj (delayInMinutes 3600)))

; (.. js/chrome -alarms (onAlarm.addListener (fn [alarm] ((when (= (.type alarm) "indexing_from_pocket")
;                                                           ((.log console "start indexing from pocket.")
;                                                            (start-index)))))))