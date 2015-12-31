(ns user
  (:require [clojure.repl :refer :all]
            [clojure.pprint :refer [pprint]]
            [clojure.tools.namespace.repl :refer [refresh]]
            [clojure.java.io :as io]
            [com.stuartsierra.component :as component]
            [eftest.runner :as eftest]
            [meta-merge.core :refer [meta-merge]]
            [reloaded.repl :refer [system init start stop go reset]]
            [ring.middleware.stacktrace :refer [wrap-stacktrace]]
            [mediaweb.config :as config]
            [mediaweb.system :as system]
            ;; deze helpt ook niet om bij (reset) views opnieuw te laden.
            ;;[mediaweb.views :as views]
            ;;[mediaweb.models :as models]
            ;;[mediaweb.helpers :as h]
            ))

;; ook deze werkt niet bij een change in views/team:
;;(def view42 (views/team 83))
;; (println view42)
;; test

#_(bla)

(def dev-config
  {:app {:middleware [wrap-stacktrace]}})

(def config
  (meta-merge config/defaults
              config/environ
              dev-config))

;; (clojure.tools.namespace.repl/set-refresh-dirs "/home/nico/nicoprjbb/sporttools/mediaweb/src/mediaweb")
;user> (reset)
;:reloading (mediaweb.helpers mediaweb.models mediaweb.views mediaweb.endpoint.mediaweb mediaweb.config mediaweb.core mediaweb.core-test mediaweb.system mediaweb.main mediaweb.endpoint.example-test user)

(defn new-system []
  (into (system/new-system config)
        {}))

(ns-unmap *ns* 'test)

(defn test []
  (eftest/run-tests (eftest/find-tests "test") {:multithread? false}))

(when (io/resource "local.clj")
  (load "local"))

(reloaded.repl/set-init! new-system)

#_(println "user.clj has finished")

