(ns mediaweb.component.db
  (:use korma.db korma.core)
  (:require [com.stuartsierra.component :as component]
            [clojure.pprint :refer [pprint]]))

;; TODO kan defdb hier zo gebruikt worden? -> lijkt van wel. Mogelijk nog eens anders.
;; TODO vraag of deze fn iets returned, dit wordt nl in :connection gezet.
(defn connect-to-database
    "Create a new postgress db connection and returns it."
    [host port dbname user password]
    (defdb db (postgres {:db dbname
                         :user user
                         :password password})))

(defrecord Database [host port dbname user password connection]
  ;; Implement the Lifecycle protocol
  component/Lifecycle

  (start [component]
    (println ";; Starting database")
    ;; In the 'start' method, initialize this component
    ;; and start it running. For example, connect to a
    ;; database, create thread pools, or initialize shared
    ;; state.
    (let [conn (connect-to-database host port dbname user password)]
      ;; Return an updated version of the component with
      ;; the run-time state assoc'd in.
      (assoc component :connection conn)))

  (stop [component]
    (println ";; Stopping database")
    ;; In the 'stop' method, shut down the running
    ;; component and release any external resources it has
    ;; acquired.
    ;; 30-12-2015 check if .close works => No and need to restart Cider.
    ;; (.close connection)
    ;; Return the component, optionally modified. Remember that if you
    ;; dissoc one of a record's base fields, you get a plain map.
    (assoc component :connection nil)))

;; Optionally, provide a constructor function that takes in
;; the essential configuration parameters of the component,
;; leaving the runtime state blank.

(defn new-database [db-config]
  #_(pprint "new-database called:")
  #_(pprint db-config)
  (map->Database db-config))


