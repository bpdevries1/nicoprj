(defproject movie "1.0.0-SNAPSHOT"
  :description "Movie information in SQLite DB."
  :dependencies [[org.clojure/clojure "1.3.0"]
                 [enlive "1.0.0"]
                 ;[lobos "1.0.0-SNAPSHOT"]
                 ;[clojureql "1.1.0-SNAPSHOT"]
                 [clojureql "1.0.3"]
                 [sqlitejdbc "0.5.6"]]
  :main movie.core)


;(defproject clojure-sqlite-example "0.1.0"
;  :description "A simple example of using SQLite with Clojure"
;  :dependencies [[org.clojure/clojure "1.2.1"]
;                 [org.clojure/java.jdbc "0.0.6"]
;                 [org.xerial/sqlite-jdbc "3.6.13"]])