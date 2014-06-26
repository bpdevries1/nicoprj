#!/bin/bash lein-exec

; handle-deleted-moved.clj - handle move and delete actions done in Krusader saved to file ~/projecten/diskcatalog/moved-deleted-files.txt

(load-file "../../clojure/lib/def-libs.clj") 
(load-file "lib-diskcat.clj")

(set-log4j! :level :debug)

(defn det-handled-path
  "Determine filename of move-deleted-files after file has been handled, sort of archive"
  [projectdir]
  (let [my-format (tf/formatter "yyyy-MM-dd--HH-mm-ss" (t/default-time-zone))]
    (fs/file (fs/expand-home projectdir) (str "moved-deleted-files-handled-" (tf/unparse my-format (t/now)) ".txt"))))

(defn delete-db-really! 
  "Delete files in path from DB and move to file_deleted"
  [db-con path]
  (jdbc/execute! db-con ["insert into file_deleted select * from file where fullpath like ?" (str path "%")])
  (jdbc/delete! db-con :file ["fullpath like ?" (str path "%")]))

(defn delete-path-db-really!
  "Delete file/dir-with-contents both from filesystem and DB"
  [db-con path]
  (when (not (nil? path))
    (let [path-fs (to-linux-path path)]
      (log/info "Really delete path: " path-fs)
      (when (fs/exists? path-fs)
        (if (fs/directory? path-fs)
          (fs/delete-dir path-fs)
          (fs/delete path-fs)))
      (delete-db-really! db-con path))))

; @todo test this fn!
; @todo also move backup files where applicable.
(defn move-db-really!
  "Move file in DB too, since it has moved in file-system.
   path-to ends with a /"
  [db-con path-from path-to]
  ; first for a single file
  (log/info "File moved from: " path-from " => " path-to)
  (let [path-to-no-slash (str/replace path-to #"/$" "")
        ; path-to-no-slash (subs path-to 0 (- (count path-to) 1))
        dir-from (fs/parent path-from)
        offset (+ 1 (count (str dir-from)))]
    (log-exprs dir-from offset path-from path-to)
    (jdbc/execute! db-con 
      ["update file
        set fullpath = ? || substr(fullpath, ?),
            folder = ? || substr(folder, ?),
            action = 'just-renamed'
        where fullpath like ?"
        path-to-no-slash offset path-to-no-slash offset (str path-from "%")])))

; @note using fs/file both path-to with or without trailing / will work.
; @todo maybe return a str instead of File object.
(defn det-moved-to-path
  "Determine new file/dir location after move action"
  [path-from path-to]
  (fs/file path-to (fs/base-name path-from)))

; @todo find src/backup combination based on backup-defs.
(defn det-backup-path
  "Return path of backup file based on source-path and backup-root.
   src-path must be a string or a File object."
  [src-path]
  (when (re-find #"^/media/nas/install/" (str src-path))
    (let [backup-root "/media/nico/Iomega HDD/backups/nas"
          skip-src ""]
      ; don't use file (join), unless first / from src-path is removed.
      (str backup-root (subs (str src-path) (count skip-src)))))) 

(defn move-backup-path-db-really! 
  "Move backup of file to new location based on path-to.
   Only if path-to is also in a location to be backed-up.
   Otherwise delete backup from filesystem and DB."
  [db-con path-from path-to]
  (when-let [orig-backup-path (det-backup-path path-from)] ; if orig file doesn't have a backup, target file will neither.
    (if-let [new-backup-path (det-backup-path (det-moved-to-path path-from path-to))]
      (do
        (log-exprs orig-backup-path new-backup-path)
        (fs/mkdirs (fs/parent new-backup-path))
        (fs/rename (det-backup-path path-from) new-backup-path) ; this could fail, best effort
        ; also in DB
        (move-db-really! db-con (det-backup-path path-from) (fs/parent new-backup-path)))
      ; else delete
      (delete-path-db-really! db-con (det-backup-path path-from)))))

(defn handle-logline
  "Handle one line of moved-deleted-files.txt"
  [line db-con backup-defs]
  (let [[cmd path1 _ path2] (str/split line #"\t")]
    (cond 
      (= cmd "delete")
        (do 
          (delete-db-really! db-con path1)
          (delete-path-db-really! db-con (det-backup-path path1)))
      (= cmd "from") 
        (do
          (move-db-really! db-con path1 path2)
          (move-backup-path-db-really! db-con path1 path2)))))

(defn read-handle 
  "Read md-files-tohandle, and handle each (moved/deleted) line"
  [db-con backup-defs md-files-tohandle]
  (let [lines (file-lines md-files-tohandle)]
    (log/info "Handle: " md-files-tohandle ", nlines: " (count lines))
    (doseq [line lines]
      (handle-logline line db-con backup-defs))))

(defn handle-deleted-moved 
  "Handle delete and moved files in Krusader: update DB and possible move/delete files in backup dirs as well"
  [db-con backup-defs opts]
  (let [dir               (fs/expand-home (:projectdir opts))
        md-files          (fs/file dir "moved-deleted-files.txt")
        md-files-tohandle (fs/file dir "moved-deleted-files-tohandle.txt")]
    (log-exprs dir md-files md-files-tohandle)
    (when (and (fs/exists? md-files)
               (not (fs/exists? md-files-tohandle)))
      (log/info "Move orig file => tohandle")
      (fs/rename md-files md-files-tohandle))
    (when (fs/exists? md-files-tohandle)
      (log/info "Tohandle exists, so do handle")
      (read-handle db-con backup-defs md-files-tohandle)
      (let [handled-path (det-handled-path (:projectdir opts))]
        (log-exprs handled-path)
        ;))))
        ; @todo deze nu even niet, ivm moeten terug-renamen
        (fs/rename md-files-tohandle handled-path)))))

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
         (handle-deleted-moved db-con backup-defs opts)))))

(main *command-line-args*)


