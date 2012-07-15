(ns movie.ddl
  ; (:refer-clojure :exclude [bigint boolean char double float time])
  (:refer-clojure :exclude [bigint boolean char double float time alter drop complement])
  (:use lobos.connectivity)
  (:use (lobos schema))
  (:use lobos.core) 
  (:use lobos.connectivity) 
  (:use lobos.migration))
  ; (:use lobos.migrations)) ; deze geeft foutmelding, overbodig?  
  
;(use 'lobos.core 'lobos.connectivity 'lobos.migration 'lobos.migrations)

;(ns lobos.helpers
;  (:refer-clojure :exclude [bigint boolean char double float time])
;  (:use (lobos schema)))



  ;(:require [clojure.contrib.sql :as sql]))
  ;(:require clojure.contrib.sql))
  ;(:use [clojure.contrib.sql :as sql :only ()]))

;(def db
;  {:classname "org.postgresql.Driver"
;   :subprotocol "postgresql"
;   :subname "//localhost:5432/test"})

(def db {
   :classname "org.sqlite.JDBC"
   :subprotocol "sqlite" ; Protocol to use
   :subname "data/movie.db" ; Location of the db
})
 
 ; deze lijkt niet nodig, db wordt sowieso wel gemaakt.
 ;(def new-db-conn (merge db {:create true}))

(defmigration add-authors-table
  ;; code be executed when migrating the schema "up" using "migrate"
  (up [] (create db
           (table :authors (integer :id :primary-key )
             (varchar :username 100 :unique )
             (varchar :password 100 :not-null )
             (varchar :email 255))))
  ;; Code to be executed when migrating schema "down" using "rollback"
  (down [] (drop (table :authors ))))

 
; (defn create-db
;  "Creates a new database and tables"
;  []
;  (sql/with-connection new-db-conn
;    (create-tables)))
; 
; (defn create-tables
;  "Creates the table needed to store the
; winners and nominees."
;  []
;  (sql/create-table
;    :nominees
;    [:id :integer "PRIMARY KEY"]
;    [:year :integer]
;    [:title "varchar(64)"]
;    [:author "varchar(32)"]
;    [:winner "tinyint"]
;    [:read_it "tinyint"]
;    [:own_it "tinyint"]
;    [:want_it "tinyint"]))

