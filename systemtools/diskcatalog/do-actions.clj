#!/bin/bash lein-exec

; delete-unwanted.clj - delete records from DB:
; - where corresponding files no longer exists in file system, from MD5 calc failure.
; - temp files, also remove from file system.

(load-file "../../clojure/lib/def-libs.clj") 
(load-file "lib-diskcat.clj")

(defn delete-file-really!
  "Delete file both from filesystem and DB"
  [db-con path]
  (println "Really delete file: " path)
  (fs/delete (to-linux-path path))
  (jdbc/delete! db-con :file ["fullpath = ?" path]))

(defn delete-file!
  "Delete file both from filesystem and DB"
  [db-con path opts]
  (if (:really opts)
    (delete-file-really! db-con path)
    (println "Dry run, don't delete: " path)))

(declare path-specs)

;; now in lib_diskcat.clj
#_(defn det-goal
  "Determine goal field based on fullpath and global var path-specs"
  [path]
  (first             ; just the key
   (first            ; only first k/v pair of filter result
    (filter
     (fn [[goal paths]]
       (some #(fs/child-of? % path) paths))
     (seq (get path-specs "goal2"))))))

(defn fs-move
  "Move a file using fs/rename or fs/copy and fs/delete.
   fs/rename only works if both locations are on the same file system."
  [source target]
  (when-not (fs/rename source target)
    (fs/copy source target)
    (fs/delete source))) 

(defn move-file-really!
  "Move file both in filesystem and in DB"
  [db-con source-path target-path]
  (println "Move file: " source-path " => " target-path)
  (fs/mkdirs (fs/parent target-path))
  #_(fs/rename source-path target-path)
  (fs-move source-path target-path)
  ;; (jdbc/update! db-spec :table {:col1 77 :col2 "456"} ["id = ?" 13]) ;; Update
  (jdbc/update! db-con :file {:fullpath target-path
                              :folder (str (fs/parent target-path))
                              :filename (str (fs/base-name target-path))
                              :goal (det-goal target-path)}
                ["fullpath = ?" source-path]))

(defn move-file!
  "Move file both in filesystem and in DB"
  [db-con source-path target-path opts]
  (if (:really opts)
    (move-file-really! db-con source-path target-path)
    (println "Dry run, don't move: " source-path)))

;; TODO copy nog niet getest.
(defn copy-file-really!
  "Move file both in filesystem and in DB"
  [db-con source-path target-path]
  (println "Copy file: " source-path " => " target-path)
  (fs/copy+ source-path target-path)
  ;; (jdbc/update! db-spec :table {:col1 77 :col2 "456"} ["id = ?" 13]) ;; Update
  ;; TODO size, ts_cet, md5, computer overnemen uit bron.
  ;; evt insert-select uitvoeren.
  (jdbc/execute!
   db-con
   ["insert into file (fullpath, folder, filename, goal, filesize,
                       ts_cet, md5, computer)
     select ?, ?, ?, ?, f.filesize, f.ts_cet, f.md5, f.computer
     from file f
     where f.fullpath = ?"
    target-path
    (str (fs/parent target-path))
    (str (fs/base-name target-path))
    (det-goal target-path)
    source-path])
  #_(jdbc/insert! db-con :file {:fullpath target-path
                              :folder (str (fs/parent target-path))
                              :filename (str (fs/base-name target-path))
                              :goal (det-goal target-path)}))

(defn copy-file!
  "Copy file both in filesystem and in DB"
  [db-con source-path target-path opts]
  (if (:really opts)
    (copy-file-really! db-con source-path target-path)
    (println "Dry run, don't copy: " source-path)))

(defn delete-action!
  "Delete action record from DB"
  [db-con id opts]
  (if (:really opts)
    (jdbc/delete! db-con :action ["id = ?" id])
    (println "Dry run, don't delete: " id)))

(defn do-actions! 
  "do actions based on action field in file and action table"
  [db-con opts]
  ;; action-field in file only for md5 calc, already in other clj file.
  #_(doseq [row (jdbc/query db-spec "select * from file where action is not null")]
    (cond (= (:action row) "if-temp-delete") 
          (do-action-if-temp-delete db-spec opts row)))
  (doseq [row (jdbc/query db-con "select * from action")]
    ;; TODO wil eigenlijk delete-action! altijd doen, maar niet als het een onbekende action is.
    (case (:action row)
      "delete" (do (delete-file! db-con (:fullpath_action row) opts)
                   (delete-action! db-con (:id row) opts))
      "mv" (do (move-file! db-con (:fullpath_other row) (:fullpath_action row) opts)
               (delete-action! db-con (:id row) opts))
      "cp" (do (copy-file! db-con (:fullpath_other row) (:fullpath_action row) opts)
               (delete-action! db-con (:id row) opts)))))

(defn main [args]
  (when-let [opts (my-cli args #{:dbspec}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-d" "--dbspec" "Database spec/config/EDN file (postgres)" :default "~/.config/media/media.edn"]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskcatalog"]
        ["-s" "--pathspecs" "Path specs file" :default "path-specs-books.clj"]
        ["-r" "--really" "Really do delete actions. Otherwise dry run" :default false :flag true])]
   (let [db-spec (db-postgres (fs/expand-home (:dbspec opts)))]
     (load-file (str (fs/file (fs/expand-home (:projectdir opts)) (:pathspecs opts))))
    (jdbc/with-db-connection [db-con db-spec]
     (do-actions! db-con opts)))))

(main *command-line-args*)

