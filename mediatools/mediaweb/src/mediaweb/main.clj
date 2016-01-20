;; ns-decl follows:
(ns mediaweb.main
  (:gen-class)
  (:require [com.stuartsierra.component :as component]
            [duct.middleware.errors :refer [wrap-hide-errors]]
            [meta-merge.core :refer [meta-merge]]
            [mediaweb.config :as config]
            [mediaweb.system :refer [new-system]]
            [mediaweb.views :as views])
  (:require
            [mediaweb.views.team :as vt]))

;; lines follow:
;; test dependencies and namespace refresh:
;; werkt dus niet, helaas.
;; (def test42 (vt/team 84))

(def prod-config
  {:app {:middleware     [[wrap-hide-errors :internal-error]]
         :internal-error "Internal Server Error"}})

(def config
  (meta-merge config/defaults
              config/environ
              prod-config))

(defn -main [& args]
  (let [system (new-system config)]
    (println "Starting HTTP server on port" (-> system :http :port))
    (component/start system)))
