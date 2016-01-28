(ns mediaweb.system
  (:require [com.stuartsierra.component :as component]
            [duct.component.endpoint :refer [endpoint-component]]
            [duct.component.handler :refer [handler-component]]
            [duct.middleware.not-found :refer [wrap-not-found]]
            [meta-merge.core :refer [meta-merge]]
            [ring.component.jetty :refer [jetty-server]]
            [ring.middleware.defaults :refer [wrap-defaults api-defaults]]
            [ring.middleware.resource :refer [wrap-resource]]
            [ring.middleware.params :refer [wrap-params]]
            [ring.middleware.keyword-params :refer [wrap-keyword-params]]
            [mediaweb.component.db :refer [new-database]]
            [mediaweb.endpoint.mediaweb :refer [mediaweb-endpoint]]
            [mediaweb.endpoint.teams :refer [teams]]
            [mediaweb.endpoint.authors :refer [authors]]
            [mediaweb.endpoint.books :refer [books]]
            [mediaweb.endpoint.bookformats :refer [bookformats]]
            [mediaweb.endpoint.directories :refer [directories]]
            [mediaweb.endpoint.actions :refer [actions]]
            [mediaweb.endpoint.files :refer [files]]
            [mediaweb.endpoint.relfiles :refer [relfiles]]
            [mediaweb.endpoint.persons :refer [persons]]
            [mediaweb.endpoint.games :refer [games]]
            [mediaweb.views :as views]
            [clojure.pprint :refer [pprint]]))

(def base-config
  {:app {:middleware [[wrap-not-found :not-found]
                      [wrap-defaults :defaults]
                      [wrap-resource :public]
                      wrap-keyword-params
                      wrap-params]
         :not-found  "Resource Not Found"
         :defaults   (meta-merge api-defaults {})
         :public     "public"}})

(defn new-system [config]
  #_(pprint "new-system called with config:")
  #_(pprint config)
  #_(pprint "base-config:")
  #_(pprint base-config)
  (let [config (meta-merge base-config config)]
    (-> (component/system-map
         :db   (new-database (:db config))
         :app  (handler-component (:app config))
         :http (jetty-server (:http config))
         :mediaweb (endpoint-component mediaweb-endpoint)
         :authors (endpoint-component authors)
         :books (endpoint-component books)
         :bookformats (endpoint-component bookformats)
         :directories (endpoint-component directories)
         :files (endpoint-component files)
         :relfiles (endpoint-component relfiles)
         :actions (endpoint-component actions)
         :teams (endpoint-component teams)
         :persons (endpoint-component persons)
         :games (endpoint-component games))
        (component/system-using
         {:http [:app]
          ;; TODO vraag of deps zo goed zijn, mogelijk mediaweb, teams etc ook afh van db.
          :app  [:mediaweb :teams :persons :games :authors :books :bookformats
                 :directories :files :relfiles :actions]
          :mediaweb [:db]}))))

