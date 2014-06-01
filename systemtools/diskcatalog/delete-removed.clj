#!/bin/bash lein-exec

; delete-removed.clj - delete records from DB where corresponding files no longer exists in file system.

(load-file "../../clojure/lib/def-libs.clj") 

(defn delete-removed! 
  "Delete records from DB where corresponding files no longer exists in file system."
  [db-spec]
  (doseq [row (jdbc/query db-spec "select fullpath from file")]
    ; (println (str "row: " row))
    (when (not (fs/exists? (:fullpath row)))
      (println (str "delete from DB (file no longer exists): " (:fullpath row)))
      (jdbc/delete! db-spec :file ["fullpath = ?" (:fullpath row)]))))
  

(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskcatalog"]
        ["-db" "--database" "Database path" :default "~/projecten/diskcatalog/bigfiles.db"]
        ["-r" "--root" "Root directory to find big files in"])]
    (let [db-spec (db-spec-path db-spec-sqlite (:database opts))]
       (delete-removed! db-spec))))

(main *command-line-args*)

