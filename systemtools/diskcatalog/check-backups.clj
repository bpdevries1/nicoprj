#!/bin/bash lein-exec

; check-backups.clj - check if every file has a backup and there are no orphan backups (without source)

(load-file "../../clojure/lib/def-libs.clj") 

(set-log4j! :level :debug)

(defn read-paths
  "Read paths from paths-file"
  [paths-file]
  (-<> (slurp paths-file)
       (str/split <> #"\n")
       (filter #(not (re-find #"^#" %)) <>)   ; ignore lines starting with #
       (filter #(not (re-find #"^$" %)) <>)   ; ignore empty lines.
       (vec <>))) 

; implementation almost the same as read-paths, don't refactor for now.
(defn read-ignores
  "Read ignore regexps from ignore-file"
  [ignore-file]
  (-<> (slurp ignore-file)
       (str/split <> #"\n")
       (filter #(not (re-find #"^#" %)) <>)   ; ignore lines starting with #
       (filter #(not (re-find #"^$" %)) <>) ; ignore empty lines.
       (map re-pattern <>)
       (vec <>)))

(defn check-backup-path
  "Check backups for one path"
  [db-con path ignores target-path]
  (log/info "Check-backup-path: params:")
  (log-exprs path ignores target-path))

(defn check-backups
  "Check if backups have been done completely and there are no orphan backups (without source)"
  [db-con backup-defs]
  (doseq [[backupname {:keys [paths-file ignore-file target-path]}] (seq backup-defs)]
    (log-exprs paths-file ignore-file target-path)
    (let [paths (read-paths paths-file)
          ignores (read-ignores ignore-file)]
      (log-exprs paths ignores)
      ; (doseq [path paths] (check-backup-path db-con path ignores target-path)))))
      (check-backup-path db-con (first paths) ignores target-path))))

; (def path-specs ) ; placeholder
(def backup-defs) ; placeholder

(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskcatalog"]
        ["-db" "--database" "Database path" :default "~/projecten/diskcatalog/bigfiles.db"])]
    (let [db-spec (db-spec-path db-spec-sqlite (:database opts))]
       (load-file (str (fs/file (fs/expand-home (:projectdir opts)) "path-specs.clj")))
       (jdbc/with-db-connection [db-con db-spec]
         (org.sqlite.Function/create (:connection db-con) "regexp" (SqlRegExp.))
         (check-backups db-con backup-defs)))))

(main *command-line-args*)

