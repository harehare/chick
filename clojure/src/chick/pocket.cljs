(ns chick.pocket
  (:require
   [ajax.core :refer [GET]]))

(defn pocket-request-url [redirect-url] (str "http://localhost:8080/oauth/request?redirect_url=" redirect-url))

(defn pocket-authorize-url [code redirect-url] (str "http://localhost:8080/oauth/authorize?code=" code "&redirect_url=" redirect-url))

(defn pocket-get-url [access-token] (str "http://localhost:8080/get?access_token=" access-token))

(def redirect-url (.. js/chrome -identity (getRedirectURL)))

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

(defn error-handler [{:keys [status status-text]}]
  (.log js/console (str "error: " status " " status-text)))

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
