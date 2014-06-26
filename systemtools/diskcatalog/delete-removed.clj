#!/bin/bash lein-exec

; delete-removed.clj - delete records from DB where corresponding files no longer exists in file system.

(load-file "../../clojure/lib/def-libs.clj") 

(set-log4j! :level :info)

; @todo move to bigfiles-lib.clj
(defn filesystems-available?
  "Check if file systems are accessible"
  [filesystems]
  (every? 
    (fn [[_name {:keys [root]}]]
      (not-empty (fs/glob (fs/file root) "*")))
    (seq filesystems)))

(defn delete-removed! 
  "Delete records from DB where corresponding files no longer exists in file system."
  [db-con opts]
  (doseq [row (jdbc/query db-con "select fullpath from file")]
    ; (println (str "row: " row))
    (when (not (fs/exists? (:fullpath row)))
      ; (println (str "delete from DB (file no longer exists): " (:fullpath row)))
      (log/info "delete from DB (file no longer exists): " (:fullpath row))
      (when (:really opts)
        (jdbc/delete! db-con :file ["fullpath = ?" (:fullpath row)])))))
  
(def filesystems) ; placeholder

(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskcatalog"]
        ["-db" "--database" "Database path" :default "~/projecten/diskcatalog/bigfiles.db"]
        ["-r" "--really" "Really do delete actions. Otherwise dry run" :default false :flag true])]
    (let [db-spec (db-spec-path db-spec-sqlite (:database opts))]
      (load-file (str (fs/file (fs/expand-home (:projectdir opts)) "path-specs.clj")))
      (if (filesystems-available? filesystems)
        (jdbc/with-db-connection [db-con db-spec]
          (log/info "All filesystems available, continue")
          (delete-removed! db-con opts))
        ; else
        (log/warn "Not all filesystems are available, so exit")))))

(main *command-line-args*)

