#!/bin/bash lein-exec

; delete-unwanted.clj - delete records from DB:
; - where corresponding files no longer exists in file system, from MD5 calc failure.
; - temp files, also remove from file system.

(load-file "../../clojure/lib/def-libs.clj") 
(load-file "lib-diskcat.clj")

(defn delete-md5-notfound!
  "Delete records from database that don't exist anymore on filesystem; here noted because MD5 calc failed"
  [db-spec opts]
  (doseq [row (jdbc/query db-spec "select fullpath from file where md5 like '%(No such file or directory)'")]
    (println (str "delete from DB (file no longer exists - md5): " (:fullpath row)))
    (when (:really opts)
      (jdbc/delete! db-spec :file ["fullpath = ?" (:fullpath row)]))))

(defn delete-file-db-really!
  "Delete file both from filesystem and DB"
  [db-spec path]
  (println "Really delete file: " path)
  (fs/delete (to-linux-path path))
  (jdbc/delete! db-spec :file ["fullpath = ?" path]))

(defn delete-file-db!
  "Delete file both from filesystem and DB"
  [db-spec path opts]
  (if (:really opts)
    (delete-file-db-really! db-spec path)
    (println "Dry run, don't delete: " path)))

(defn delete-double-temp-files!
  "Delete files marked as temp iff another non-temp file exists with the same name, size and md5"
  [db-spec opts]
  (doseq [row (jdbc/query db-spec "select f1.fullpath fullpath, f2.fullpath fullpath2
          from file f1, file f2
          where f1.filename = f2.filename
          and f1.filesize = f2.filesize
          and f1.md5 = f2.md5
          and f1.srcbak = 'temp'
          and f2.srcbak <> 'temp'")]
    (println (str "delete from filesys/DB (tempfile): " (:fullpath row) ", other file: " (:fullpath2 row)))
    (delete-file-db! db-spec (:fullpath row) opts)))

; deze mss overbodig door action/if-temp-delete
(defn delete-single-temp-files!
  "Deleted files marked as temp and having a filename which signifies auto-save"
  [db-spec opts]
  (doseq [row (jdbc/query db-spec "select fullpath from file where srcbak='temp'
                                   and (filename like '#%#' or filename like '%~')")]
    (println (str "delete from filesys/DB (tempfile): " (:fullpath row)))
    (delete-file-db! db-spec (:fullpath row) opts)))

(defn do-action-if-temp-delete
  "if action is if-temp-delete and srcbak is temp, then delete this file"
  [db-spec opts row]
  (when (= (:srcbak row) "temp")
    (println (str "delete from filesys/DB (if-temp-delete): " (:fullpath row)))
    (delete-file-db! db-spec (:fullpath row) opts)))

; deze mss moven naar losse clj file, mv ook met moven van files
(defn do-actions! 
  "do actions based on action field in file and possibly other info"
  [db-spec opts]
  (doseq [row (jdbc/query db-spec "select * from file where action is not null")]
    (cond (= (:action row) "if-temp-delete") 
      (do-action-if-temp-delete db-spec opts row))))

(defn delete-unwanted!
  "Delete files that are unwanted: in unwanted locations or also located elsewhere. 
    Only if -r is given, files are actually deleted."
  [db-spec opts]
  (delete-md5-notfound! db-spec opts)
  (delete-double-temp-files! db-spec opts)
  (delete-single-temp-files! db-spec opts)
  (do-actions! db-spec opts))

(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskcatalog"]
        ["-db" "--database" "Database path" :default "~/projecten/diskcatalog/bigfiles.db"]
        ["-r" "--really" "Really do delete actions. Otherwise dry run" :default false :flag true])]
    (let [db-spec (db-spec-path db-spec-sqlite (:database opts))]
       (delete-unwanted! db-spec opts))))

(main *command-line-args*)

