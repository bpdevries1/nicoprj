#!/bin/bash lein-exec

; removelinks-db.clj - remove files from bigfiles.db that are symlinks or hardlinks.

(load-file "../../clojure/lib/def-libs.clj") 

(def db-spec-sqlite {:classname "org.sqlite.JDBC"
                     :subprotocol "sqlite"})

(defn remove-links 
  "remove records in db-spec for files that are links"
  [db-spec]
  (doseq [row (jdbc/query db-spec "select fullpath from file")]
    ; (println (str "row: " row))
    (when (fs/link? (:fullpath row))
      (println (str "delete from DB (link): " (:fullpath row)))
      (jdbc/delete! db-spec :file ["fullpath = ?" (:fullpath row)]))))

(def required-opts #{:database})

(defn missing-required?
  "Returns true if opts is missing any of the required-opts"
  [opts]
  (not-every? opts required-opts))

(defn main [args]
  ; args contains scriptname as first item, don't give to 'cli'
  (println "Started")
  (let [[opts args banner] (cli (rest args)
            ["-h" "--help" "Print this help"
                  :default false :flag true]
            ["-db" "--database" "Database path" :default "~/projecten/diskcatalog/bigfiles.db"]
            ["-r" "--root" "Root directory to find big files in"])]
  (if (or (:help opts)
          (missing-required? opts))
    (println banner)
    (do (println (str "opts: " opts ", remaining args: " args))
        (let [db-spec (create-db opts)]
          (remove-links db-spec))
        (println "Finished")))))

(main *command-line-args*)

