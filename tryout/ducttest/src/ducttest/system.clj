(ns ducttest.system
  (:require [clojure.java.io :as io]
            [com.stuartsierra.component :as component]
            [duct.component.endpoint :refer [endpoint-component]]
            [duct.component.handler :refer [handler-component]]
            [duct.component.hikaricp :refer [hikaricp]]
            [duct.middleware.not-found :refer [wrap-not-found]]
            [duct.middleware.route-aliases :refer [wrap-route-aliases]]
            [meta-merge.core :refer [meta-merge]]
            [ring.component.jetty :refer [jetty-server]]
            [ring.middleware.defaults :refer [wrap-defaults site-defaults]]
            [ring.middleware.webjars :refer [wrap-webjars]]
            [ducttest.endpoint.example :refer [example-endpoint]]
            [clojure.pprint :refer [pprint]]))

(def base-config
  {:app {:middleware [[wrap-not-found :not-found]
                      [wrap-webjars]
                      [wrap-defaults :defaults]
                      [wrap-route-aliases :aliases]]
         :not-found  (io/resource "ducttest/errors/404.html")
         :defaults   (meta-merge site-defaults {:static {:resources "ducttest/public"}})
         :aliases    {"/" "/index.html"}}})

(defn new-system [config]
  (pprint "new-system called with config:")
  (pprint config)
  (pprint "base-config:")
  (pprint base-config)

  (let [config (meta-merge base-config config)]
    (-> (component/system-map
         :app  (handler-component (:app config))
         :http (jetty-server (:http config))
         :db   (hikaricp (:db config))
         :example (endpoint-component example-endpoint))
        (component/system-using
         {:http [:app]
          :app  [:example]
          :example [:db]}))))
