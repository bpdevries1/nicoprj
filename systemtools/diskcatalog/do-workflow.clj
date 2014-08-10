#!/bin/bash lein-exec

;{[(
; do-workflow.clj - check for and do actions based on workflow definitions.
; can be called directly or from do-cron.clj

(load-file "../../clojure/lib/def-libs.clj") 
(load-file "lib-diskcat.clj")

(set-log4j! :level :debug)

(defn handle-no-source-check-other-source
  "Set file status of 'no-source' to 'no-source-other-source' iff another file found"
  [db-con opts]
  (let [sql "select f.id id, f.fullpath fullpath, f.status status, s.fullpath src_fullpath
                   from file_with_status f
                   join file s on s.filename = f.filename
                     and s.filesize = f.filesize
                     and s.md5 = f.md5
                     and s.ts_cet = f.ts_cet
                   where s.srcbak = 'source'
                   and f.srcbak = 'backup'
                   and f.status = 'no-source'"
       res1 (vec (jdbc/query db-con sql))
       res (group-by (fn [m] (select-keys m [:id :fullpath :status])) res1)]
    (log-exprs res1 res)
    (doseq [[{:keys [id fullpath status]} srclist] res]
      (log/debug "Found sources for: " fullpath)
      (log-exprs srclist)
      ; split srclist in files that do and don't exist.
      ; 'separate' function from clojure contrib. => tot 1.2, onduidelijk waar het nu staat, eerst maar even zonder.
      (let [src-exist (filter #(fs/exists? (:src_fullpath %)) srclist)
            src-no-exist (remove #(fs/exists? (:src_fullpath %)) srclist)] ; could also use juxt
        (if (empty? src-exist)
          (update-file-status-log-info! db-con id fullpath status "no-source-unique"
            "Only non-existing source(s) found for this backup, check this backup"
            "handle-no-source-check-other-source")
          (update-file-status-log-info! db-con id fullpath status "no-source-other-source"
            "Other source found for this backup, delete this backup"
            "handle-no-source-check-other-source"
            "other-source" (:src_fullpath (first src-exist))))
        (doseq [{:keys [src_fullpath]} src-no-exist]
          (delete-db-really! db-con src_fullpath))))))

; @todo sowieso maken.
; @todo ook onderscheid maken: helemaal geen andere file, wel andere source maar bestaat niet, wel andere
; file maar geen source, wel een andere source (met dezelfde md5 en/of naam) maar niet alle velden hetzelfde.
(defn handle-no-source-rest
  "Set file status of 'no-source' to 'no-source-unique'.
   @pre handle-no-source-check-other-source has just been executed"
  [db-con opts]
  (let [sql "select f.id id, f.fullpath fullpath, f.status status
                   from file_with_status f
                   where f.srcbak = 'backup'
                   and f.status = 'no-source'"
       res (jdbc/query db-con sql)]
    (doseq [{:keys [id fullpath status]} res]
      (update-file-status-log-info! db-con id fullpath status "no-source-unique"
            "No existing source(s) found for this backup, check this backup"
            "handle-no-source-rest"))))
  
(defn handle-no-source
  "Handle backup files without a corresponding source file:
   mark for deletion iff file exists at another location. If not, mark
   as no-source, unique file"
  [db-con opts]
  ; @todo check of [db-con db-con] ook mag.
  (jdbc/with-db-transaction [tdb-con db-con]
    (handle-no-source-check-other-source tdb-con opts)
    (handle-no-source-rest tdb-con opts)))

(defn handle-no-source-other-source
  "Delete files with status=no-source-other-source"
  [db-con opts]
  (jdbc/with-db-transaction [tdb-con db-con]
    ; vec to realise the lazy sequence. Should be fixed, because the DB updates may change the result.
    (let [res (vec (jdbc/query tdb-con
              ["select fullpath from file_with_status where status = ?" "no-source-other-source"]))]
      (log/info "#records to delete: " (count res))
      (doseq [{:keys [fullpath]} res]
        (delete-path-db-really! tdb-con fullpath)))))

(defn do-workflow
  "Check for and do workflow actions"
  [db-con opts]
  (handle-no-source db-con opts)
  (handle-no-source-other-source db-con opts))

(def backup-defs) ; placeholder

(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskcatalog"]
        ["-db" "--database" "Database path" :default "~/projecten/diskcatalog/bigfiles.db"])]
    (let [db-spec (db-spec-path db-spec-sqlite (:database opts))]
       ; (load-file (str (fs/file (fs/expand-home (:projectdir opts)) "path-specs.clj")))
       (jdbc/with-db-connection [db-con db-spec]
         (org.sqlite.Function/create (:connection db-con) "regexp" (SqlRegExp.))
         (do-workflow db-con opts)))))

(when (is-cmdline?)
  (main *command-line-args*))

;)]}
