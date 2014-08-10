#!/bin/bash lein-exec

;{[(
; check-backups.clj - check if every file has a backup and there are no orphan backups (without source)

(load-file "../../clojure/lib/def-libs.clj") 
(load-file "lib-diskcat.clj")

(set-log4j! :level :debug)

(defn det-backup-path
  "Return path of backup file based on source-path and backup-root"
  [src-path backup-root skip-src]
  ; for now just join the paths
  ; @todo for windows files, something else is needed
  (str backup-root (subs src-path (count skip-src)))) ; don't use file (join), unless first / from src-path is removed.

(defn ignore-file?
  "Return true if file should be ignored based on list of regexp's in ignores"
  [path ignores]
  (some #(re-find % path) ignores))

; @todo target-path should become (path-remove-slash target-path), but then check adding of subst etc.
; @todo incremental version of this one, only add new files?
(defn fill-srcbak
  "Fill srcbak table for one path"
  [db-con path ignores target-path skip-src]
  (log/debug "fill-srcbak: " path)
  (log-exprs path ignores target-path skip-src)
  (jdbc/execute! db-con 
    ["insert into srcbak (id_src, id_bak, fullpath_src, fullpath_bak, ts_cet_src, ts_cet_bak, 
                          filesize_src, filesize_bak, md5_src, md5_bak)
      select fs.id, ft.id, fs.fullpath, ft.fullpath, fs.ts_cet, ft.ts_cet, 
             fs.filesize, ft.filesize, fs.md5, ft.md5
      from file fs, file ft
      where fs.fullpath like ?
      and ft.fullpath = ? || substr(fs.fullpath, ? + 1)" 
     (path-add-perc path) target-path (count skip-src)]))

(defn check-backup-src 
  "Check backups from a source perspective: target does not exist."
  [db-con path ignores target-path skip-src]
  (let [sql "select id, fullpath, status from file_with_status
             where fullpath like ?
             and status is null
             and not fullpath in (
               select sb.fullpath_src
               from srcbak sb
               where sb.fullpath_src like ?
             )"
        path_like (path-add-perc path)]
    (doseq [{:keys [id fullpath status]} (jdbc/query db-con [sql path_like path_like])]
      (when (not (ignore-file? fullpath ignores))
        ; ignore type A: only src, but in ignore-list, so ok.
        ; here handle type D: only src, but do expect a backup.
        (let [path2 (det-backup-path fullpath target-path skip-src)
              [new-status notes action] 
                (if (fs/exists? path2)
                  ["no-backup-db" (str "No backup found in DB for: " fullpath " -> " path2 " => run-bigfiles2db") "run-bigfiles2db"]
                  ["no-backup-db-fs" (str "No backup found in DB and file system for: " fullpath " -> " path2 " => backup-file") "backup-file"])]
          (log/warn notes)
          (update-file-status-log-info! db-con id fullpath status new-status notes 
            "check-backups" "backup-path" path2))))))

(defn check-backup-src-old
  "Check backups from a source perspective: target does not exist."
  [db-con path ignores target-path skip-src]
  (let [sql "select fullpath from file fs
             where fullpath like ?
             and not fullpath in (
               select sb.fullpath_src
               from srcbak sb
               where sb.fullpath_src like ?
             )"
        path_like (path-add-perc path)]
    (doseq [{:keys [fullpath]} (jdbc/query db-con [sql path_like path_like])]
      (when (not (ignore-file? fullpath ignores))
        ; ignore type A: only src, but in ignore-list, so ok.
        ; here handle type D: only src, but do expect a backup.
        (let [path2 (det-backup-path fullpath target-path skip-src)
              [notes action] 
                (if (fs/exists? path2)
                  [(str "No backup found in DB for: " fullpath " => " path2) "run-bigfiles2db"]
                  [(str "No backup found in DB and file system for: " fullpath " => " path2) "backup-file"])]
          (log/warn notes)
          (jdbc/insert! db-con :action {:action action :notes notes 
            :fullpath_action fullpath :fullpath_other path2}))))))
 
(defn check-backup-both
  "Check backups from both perspectives: target does exist."
  [db-con path ignores target-path]
  (log/info "Check backup both for path: " path)
  (let [sql "select * from srcbak sb
               left join filestatus fs on fs.file_id = sb.id_src
             where sb.fullpath_src like ?
             and fs.status is null"
        path_like (path-add-perc path)]
    (doseq [{:keys [id_src id_bak fullpath_src fullpath_bak ts_cet_src ts_cet_bak 
                    filesize_src filesize_bak md5_src md5_bak]} 
                (jdbc/query db-con [sql path_like])]
      ; (log/info "Check backup both: " fullpath_src)                
      (if (ignore-file? fullpath_src ignores)
        (let [notes (str "Unjust backup of " fullpath_src ", remove backup file")]
          (log/warn notes)
          ; @todo? determine old-status (both from source and backup?)
          (update-file-status-log-info! db-con id_src fullpath_src :unknown "has-unjust-backup" notes 
            "check-backups" "backup-path" fullpath_bak)
          (update-file-status-log-info! db-con id_bak fullpath_bak :unknown "unjust backup" notes 
            "check-backups" "source-path" fullpath_src))
          ;(jdbc/insert! db-con :action {:action "remove-backup" :notes notes 
          ;  ; of orig = bak, other = src => orig moet je hier deleten.
          ;  :fullpath_action fullpath_bak :fullpath_other fullpath_src}))
      ; else: ok, there's a backup, check ts, size and md5
        (if (and (= filesize_src filesize_bak) (= md5_src md5_bak))
          (if (= ts_cet_src ts_cet_bak)
            nil ; ok: backup is recent backup.
            (let [new-status "backup=src,ts-differ"
                  notes "Backup is same as src, ts's differ"]
              (update-file-status-log-info! db-con id_src fullpath_src :unknown new-status 
                notes "check-backups" "backup-path" fullpath_bak)
              (update-file-status-log-info! db-con id_bak fullpath_bak :unknown new-status 
                notes "check-backups" "source-path" fullpath_src)))
            ;(jdbc/insert! db-con :action {:action "touch-backup" :notes "Backup is same as src, ts's differ"
            ;  :fullpath_action fullpath_src :fullpath_other fullpath_bak}))
          (let [[action notes] (cond 
            (or (= "" (str md5_src)) (= "" (str md5_bak))) ["do-md5" "MD5 is empty, do calculation"]
            :else ["backup-file" (str "Backup is old, do again. md5_bak=" md5_bak ".")])]
            (update-file-status-log-info! db-con id_src fullpath_src :unknown action 
              notes "check-backups" "backup-path" fullpath_bak)
            (update-file-status-log-info! db-con id_bak fullpath_bak :unknown action 
              notes "check-backups" "source-path" fullpath_src)))))))
            ;(jdbc/insert! db-con :action  {:action action :notes notes
            ;  :fullpath_action fullpath_src :fullpath_other fullpath_bak})))))))
        
(defn check-backup-target 
  "Check backups from backup perspectives: src does exist."
  [db-con target-path]
  (log/info "Check backup target for path: " target-path)
  (let [sql "select id, fullpath, status from file_with_status fs
             where fullpath like ?
             and status is null
             and not fullpath in (
               select sb.fullpath_bak
               from srcbak sb
               where sb.fullpath_bak like ?
             )"
        path_like (path-add-perc target-path)]
    (doseq [{:keys [id fullpath status]} (jdbc/query db-con [sql path_like path_like])]
      (let [notes (str "No source file found for: " fullpath)]
        (log/info notes)
        (update-file-status-log-info! db-con id fullpath status "no-source" 
              notes 
              "check-backups" nil nil)))))
        
        ;(jdbc/insert! db-con :action {:action "delete-file" :notes notes 
        ;  :fullpath_action fullpath})))))

(defn check-backups
  "Check if backups have been done completely and there are no orphan backups (without source)"
  [db-con backup-defs opts]
  (when (:clear opts)
    (jdbc/db-do-commands db-con
      "delete from srcbak"
      "delete from action"))
  (doseq [[backupname {:keys [paths-file ignore-file target-path skip-src]}] (seq backup-defs)]
    (log-exprs paths-file ignore-file target-path)
    (let [cache-dir (fs/file (fs/expand-home (:projectdir opts)) ".backupdef-cache" backupname)
          paths ((make-cacheable read-paths cache-dir) paths-file)
          ignores ((make-cacheable read-ignores cache-dir) ignore-file)]
      (log-exprs cache-dir paths ignores)
      (doseq [path paths] 
        (fill-srcbak db-con path ignores target-path skip-src)
        (check-backup-src db-con path ignores target-path skip-src)
        (check-backup-both db-con path ignores target-path))
      (check-backup-target db-con target-path))))

(def backup-defs) ; placeholder

(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskcatalog"]
        ["-db" "--database" "Database path" :default "~/projecten/diskcatalog/bigfiles.db"]
        ["-c" "--clear" "Clear tables srcbak and action before starting" :default false :flag true])]
    (let [db-spec (db-spec-path db-spec-sqlite (:database opts))]
       (load-file (str (fs/file (fs/expand-home (:projectdir opts)) "path-specs.clj")))
       (jdbc/with-db-connection [db-con db-spec]
         (org.sqlite.Function/create (:connection db-con) "regexp" (SqlRegExp.))
         (check-backups db-con backup-defs opts)))))

(when (is-cmdline?)
  (main *command-line-args*))

;)]}
