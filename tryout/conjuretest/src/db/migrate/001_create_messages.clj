(ns db.migrate.001-create-messages
  (:use conjure.core.model.database))

(defn
#^{:doc "Migrates the database up to version 1."}
  up []
  (create-table "messages" 
    (id)
    (string "text")))
  
(defn
#^{:doc "Migrates the database down from version 1."}
  down []
  (drop-table "messages"))