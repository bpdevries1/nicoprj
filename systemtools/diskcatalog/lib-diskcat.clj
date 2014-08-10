; lib-diskcat.clj - library with function for diskcatalog clojure scripts.

; c:\bieb\ICT-books\(eBook - comp) Introduction To Evolutionary Computing - A.eiben,j.smith (2003).djvu
; => /media/laptop/bieb/ICT-books/(eBook - comp) Introduction To Evolutionary Computing - A.eiben,j.smith (2003).djvu
(defn to-linux-path 
  "Convert laptop/windows path like c:\\bieb to /media/laptop/bieb"
  [path]
  (if-let [[_ part] (re-find #"^c:.(.*)$" path)] 
    (str "/media/laptop/" (clojure.string/replace part "\\" "/"))
    path))

(defn path-remove-slash
  "Remove possible final slash from path"
  [path]
  (str/replace path #"/$" ""))

(defn path-add-perc
  "Add /% to path to be used in SQL query. Make sure no double // occurs"
  [path]
  (let [path-no-slash (path-remove-slash path)]
    (str path-no-slash "/%")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; workflow: update filestatus, filelog and fileinfo tables

(defn get-file-id
  "get file id based on fullpath, nil if not found"
  [db-con fullpath]
  (let [sql "select id from file where fullpath = ?"]
    (-> (jdbc/query db-con [sql fullpath])
        first
        :id)))

(defn get-file-deleted-id
  "get file_deleted id based on fullpath, nil if not found"
  [db-con fullpath]
  (let [sql "select id from file_deleted where fullpath = ?"]
    (-> (jdbc/query db-con [sql fullpath])
        first
        :id)))

; @param id: file id (not filestatus id!)
(defn get-file-status
  "get current file status from DB, nil if not found"
  [db-con id]
  (let [sql "select status from filestatus where file_id = ?"]
    (-> (jdbc/query db-con [sql id])
        first
        :status)))

; if id is nil it is retrieved based on fullpath.
; @param id: id of file (or id of filestatus???)
(defn update-file-status!
  "Insert filestatus record of update current one"
  [db-con id fullpath old-status new-status notes]
  (let [id2 (if (nil? id) (get-file-id db-con fullpath) id)
        old-status2 (if (= :unknown old-status)
                      (get-file-status db-con id2)
                      old-status)]
    (if (nil? id2)
      (do 
        (log/warn "id2 is nil for fullpath: " fullpath)
        (log/warn "id in file_deleted: " (get-file-deleted-id db-con fullpath)))
      (if (nil? old-status2)
        (jdbc/insert! db-con :filestatus {:file_id id2 :fullpath fullpath :status new-status :notes notes})
        (jdbc/execute! db-con ["update filestatus set fullpath = ?, status = ?, notes = ?, 
                                ts_cet = strftime('%Y-%m-%d %H:%M:%S','now', 'localtime')
                                where file_id = ?" fullpath new-status notes id2])))))

; @todo infoname/value als optional fields, evt met & rest.
(defn update-file-status-log-info!
  "update filestatus, insert into fileinfo and filelog"
  [db-con id fullpath old-status new-status notes action & rest]
  (update-file-status! db-con id fullpath old-status new-status notes)
  (jdbc/insert! db-con :filelog {:file_id id :fullpath fullpath :action "check-backups" :notes notes
                                 :oldstatus old-status :newstatus new-status})
  (when-let [[infoname infovalue] rest]
    (jdbc/insert! db-con :fileinfo {:file_id id :fullpath fullpath :name infoname :value infovalue 
                                    :notes notes})))  

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; deleting files and moving record to file_deleted table
(defn delete-db-really! 
  "Delete files in path from DB and move to file_deleted"
  [db-con path]
  (log/info "Deleting from DB: " path)
  (let [path-like (path-add-perc path)]
  ; @todo when path is a dir, update-file-status! does not work yet
    (update-file-status! db-con nil path :unknown "deleted" "File deleted")
    (jdbc/execute! db-con 
      ["insert into file_deleted select * from file where fullpath = ? or fullpath like ?" 
       path path-like])
    (jdbc/delete! db-con :file ["fullpath = ? or fullpath like ?" path path-like])))

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

;;;;;;;;;;;;;;;;;;;;;;;;;;
; cached-path and make-cacheable belong together

(defn cached-path
  "Returns (normally local) cached version of (possible remote) path: first tries to copy path to cache-dir,
   then returns cache-dir path. If copy fails, just return the cached version."
  [path cache-dir]
  (let [local-path (fs/file (fs/expand-home cache-dir) (fs/base-name path))]
    (try 
      (fs/copy+ (fs/expand-home path) local-path)       ; copy+ makes dirs where needed.
      (catch java.io.IOException e nil)                 ; this one expected when file not found.
      (catch java.lang.IllegalArgumentException e nil)) ; this one returned by fs/copy+ if file not found.
    local-path))

(defn make-cacheable
  "Make new function from f, where first param is replaced by (cached-path param)"
  [f cache-dir]
  (fn [path & args]
    (apply f (cached-path path cache-dir) args)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn file-lines
  "Read lines from files; ignore empty lines and lines starting with #"
  [path]
  (-<> (slurp path)
       (str/split <> #"\r?\n")
       (filter #(not (re-find #"^#" %)) <>)   ; ignore lines starting with #
       (filter #(not (re-find #"^$" %)) <>)))

; a path in paths is one of the following:
; <just-path>
; <path> <tab> <level>
; remove the <tab> and <level> here.
(defn read-paths
  "Read paths from paths-file"
  [paths-file]
  (->> paths-file
       file-lines
       (map #(first (str/split % #"\t")))
       (map to-linux-path)
       vec))
  
(defn read-ignores
  "Read ignore regexps from ignore-file"
  [ignore-file]
  ; (vec (map re-pattern (file-lines ignore-file)))
  (->> ignore-file file-lines (map re-pattern) vec))


