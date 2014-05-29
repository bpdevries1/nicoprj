#!/bin/bash lein-exec

; delete-unwanted.clj - delete records from DB where corresponding files no longer exists in file system, from MD5 calc failure.
; could also be that files were locked during MD5 calc.
; so need an extra check in MD5 calc.

(load-file "../../clojure/lib/def-libs.clj") 

(defn delete-md5-notfound!
  "Delete records from database that don't exist anymore on filesystem; here noted because MD5 calc failed"
  [db-spec opts]
  (doseq [row (jdbc/query db-spec "select fullpath from file where md5='file-not-found'")]
    (println (str "dekete from DB (file no longer exists - md5): " (:fullpath row)))
    (when (not (:nothing opts))
      (jdbc/delete! db-spec :file ["fullpath = ?" (:fullpath row)]))))

(defn delete-unwanted!
  "Delete files that are unwanted: in unwanted locations or also located elsewhere. 
    If -n is given, nothing is actually deleted."
  [db-spec opts]
  (delete-md5-notfound! db-spec opts))

(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskcatalog"]
        ["-db" "--database" "Database path" :default "~/projecten/diskcatalog/bigfiles.db"]
        ["-n" "--nothing" "Do nothin, dry run" :default false :flag true])]
    (let [db-spec (db-spec-path db-spec-sqlite (:database opts))]
       (delete-unwanted! db-spec opts))))

(main *command-line-args*)

