(ns movie.dml
  (:refer-clojure :exclude [take drop sort distinct compile conj! disj! case]) ; 31-12-2011 deze constructie in SocialSite gezien (Lau Jensen), ook case erbij gezet.
  (:use clojureql.core))
  ;)

(defn insert-imdb
  "Insert records in movie.db sqlite3 file, in imdb table"
  [movies]
  (clojureql.core/conj! (table :imdb) movies))

(def db {
   :classname "org.sqlite.JDBC"
   :subprotocol "sqlite" ; Protocol to use
   :subname "data/movie.db" ; Location of the db
})

(open-global db) ; # geen connectie name, gebruik default.

(defn open-global-db []
  (open-global db))

(defn close-global-db []
  (close-global))  

