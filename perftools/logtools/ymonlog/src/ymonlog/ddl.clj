(ns ymonlog.ddl
  (:refer-clojure :exclude [take drop sort distinct compile conj! disj! case]) ; 31-12-2011 deze constructie in SocialSite gezien (Lau Jensen), ook case erbij gezet.
  (:require lobos.connectivity  ; 8-1-12 remove for now, name clashes with clojureQL. maybe better to create db in a separate namespace with separate use's.
            lobos.core
            lobos.schema))

;"/tmp/cql.sqlite3"
; @todo iets als with-db te doen ipv global?
; @todo andere tabel voor acties met looptijden.
(defn create-log-db 
  "Create sqlite db to put log data in"
  [db]
  (lobos.connectivity/open-global db)
  (lobos.core/create 
    (lobos.schema/table :event 
      (lobos.schema/char :ts 25) 
      (lobos.schema/char :type 20) 
      (lobos.schema/char :monitor 50) 
      (lobos.schema/text :logtext)))
  (lobos.core/create 
    (lobos.schema/table :interval 
      (lobos.schema/char :ts_start 25) 
      (lobos.schema/char :ts_end 25) 
      (lobos.schema/char :type 20) 
      (lobos.schema/char :monitor 50) 
      (lobos.schema/char :status 20)
      (lobos.schema/text :logtext)))
  (lobos.connectivity/close-global))


