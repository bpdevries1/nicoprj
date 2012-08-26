#!/bin/bash lein-exec

(use '[leiningen.exec :only  (deps)])
(deps '[[org.clojure/java.jdbc "0.1.1"]
        [org.xerial/sqlite-jdbc "3.7.2"]])

;(use 'java.jdbc)
(require '[clojure.java.jdbc :as jdbc])
(require '[clojure.java.io :as io])
;(require '[clojure.pprint :as pprint])

; 26-8-2012 NdV onderstaande werken beide!
; (use '[clojure.pprint])
(use 'clojure.pprint)

(println "jdbc hello world, java.jdbc and sqlite loaded succesfully!")

; remove orig test.db
(io/delete-file (io/file "test.db"))

(def db-spec {:classname "org.sqlite.JDBC"
              :subprotocol "sqlite"
              :subname "test.db"})

(jdbc/with-connection db-spec)

(println "Connected (and created?) db")

(jdbc/with-connection db-spec
  (jdbc/create-table :authors
    [:id "integer primary key"]
    [:first_name "varchar"]
    [:last_name "varchar"]))

(println "Created table authors")

(jdbc/with-connection db-spec
  (jdbc/transaction
    (jdbc/insert-records :authors
      {:first_name "Chas" :last_name "Emerick"}
      {:first_name "Christophe" :last_name "Grand"}
      {:first_name "Brian" :last_name "Carper"})))

(println "Inserted records into table authors within transaction")

; (pprint/pprint '(1 2 3))
(pprint '(1 2 3))

(pprint
  (jdbc/with-connection db-spec
    (jdbc/with-query-results res ["SELECT * FROM authors"]
      (doall res))))

(println "Selected records")



(println "END-OF-SCRIPT")



