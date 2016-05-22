(ns ymonlog.dml
  (:refer-clojure :exclude [take drop sort distinct compile conj! disj! case]) ; 31-12-2011 deze constructie in SocialSite gezien (Lau Jensen), ook case erbij gezet.
  ;(:refer-clojure :exclude [bigint boolean char double float time])           ; deze voor Lobos, nu even niet.
  (:use clojureql.core ))

(defn open-db [db]
  (open-global db))

(defn close-db []
  (close-global))

(defn insert-db [atable values]
  "Insert hashmap in database"
  (clojureql.core/conj! 
    (table atable) values)) 
  
(defn insert-db-event [event]
  "Insert hashmap event in database"
  (insert-db :event event))

(defn insert-db-interval [interval]
  "Insert hashmap interval in database"
  (insert-db :interval interval))
  
