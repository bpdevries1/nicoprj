(defproject ymonlog "1.0.0-SNAPSHOT"
  :description "Analyse ymonitor logs."
  :dependencies [[org.clojure/clojure            "1.3.0"]
                 [org.clojure/clojure-contrib    "1.2.0"]
                 [org.clojure/java.jdbc          "0.1.1"]          ; referred by clojureQL, needed for direct SQL? or Lobos?
                 [clojureql                      "1.0.3"]          ; DML  
                 [lobos                          "1.0.0-SNAPSHOT"] ; DDL
                 [clj-time                       "0.3.4"]
                 [sqlitejdbc                     "0.5.6"]          ; searching Clojars
                 [org.xerial/sqlite-jdbc         "3.7.2"]]         ; referred by clojureQL
  :main ymonlog.core)


