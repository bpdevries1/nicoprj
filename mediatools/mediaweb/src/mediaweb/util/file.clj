(ns mediaweb.util.file
  (:require
   [clojure.java.io :as io] 
   [clojure.string :as str]
   [me.raynes.fs :as fs]
   [clojure.java.jdbc :as jdbc]
   [clojure.tools.cli :refer [cli]]
   [swiss.arrows :refer :all] ; bij deze refer all wel handig, met -<> operators, wil hier geen namespace voor.
   [clojure.tools.logging :as log]
   [clj-logging-config.log4j :as logcfg]
   [clojure.edn :as edn]
   [clj-time.core :as t]
   [clj-time.coerce :as tc]
   [clj-time.format :as tf]
   [korma.db :refer :all]
   [korma.core :refer :all]
   [libndv.core :as h]
   [libndv.coerce :refer [to-float to-int to-key]]
   [libndv.debug :as dbg]
   [mediaweb.models.entities :refer :all]))

;; TODO: restructure lib/ns.

;; directory/path functions

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

(defn path-relative
  "Determine relative pathname from path relative to root.
  Return sequence of path elements.
  @pre path is a descendent of root"
  [path root]
  (drop (count (fs/split root)) (fs/split path)))

(defn path-target
  "Determine target full path based on source full path, source root and target root.
  Returns a file object"
  [source-path source-root target-root]
  (apply fs/file target-root (path-relative source-path source-root)))

(declare path-specs)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; determine goal based on fullpath
(defn det-goal
  "Determine goal field based on fullpath and global var path-specs"
  [path]
  (first             ; just the key
   (first            ; only first k/v pair of filter result
    (filter
     (fn [[goal paths]]
       (some #(fs/child-of? % path) paths))
     (seq (get path-specs "goal2"))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; workflow: update filestatus, filelog and fileinfo tables

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
  ;; (->> ignore-file file-lines (map re-pattern) vec)
  ;; mapv should work, not tested yet (8-4-2016).
  (->> ignore-file file-lines (mapv re-pattern)))

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
    (println "Dry run, don't delete: " path))
  :ok)

;; (declare path-specs)

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
  (fs-move source-path target-path)
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
    (println "Dry run, don't move: " source-path))
  :ok)

;; TODO: copy nog niet getest.
;; TODO: insert-select ook met korma te doen? Of alleen door data eerst naar client te halen? Hoeft btw niet een probleem te zijn met beperkte sets.
(defn copy-file-really!
  "Move file both in filesystem and in DB"
  [db-con source-path target-path]
  (println "Copy file: " source-path " => " target-path)
  (fs/copy+ source-path target-path)
  ;; (jdbc/update! db-spec :table {:col1 77 :col2 "456"} ["id = ?" 13]) ;; Update
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

;; TODO: iets met copy-file! en copy-file-really!, deze structuur komt paar keer voor, moet dus handiger kunnen.
(defn copy-file!
  "Copy file both in filesystem and in DB"
  [db-con source-path target-path opts]
  (if (:really opts)
    (copy-file-really! db-con source-path target-path)
    (println "Dry run, don't copy: " source-path))
  :ok)

(defn line->map
  "Convert line in form of key: value to a map with lowercase key. Return nil for invalid formats."
  [line]
  (let [[k v] (drop 1 (first (re-seq #"^([^:]+): *(.*)$" (or line ""))))]
    (if k
      {(keyword (str/lower-case k)) v})))

;; TODO put in test functions within lein project.
;;(line->map "key 1:    value 2")
;;(line->map "abc")
;;(line->map nil)

(defn file-title
  "Return filename without extension from path. Replace underscores etc by spaces"
  [path]
  (fs/base-name path true))

(defn get-pdfinfo
  "Get PDF info from PDF file using pdfinfo.
   <deze geeft een goede map terug, dus met title=file als pdf.title leeg is.>"
  [path]
  (let [res (fs/exec "pdfinfo" path)]
    (when (= (:exit res) 0)
      (let [m (apply merge (map line->map (str/split (:out res) #"\n")))
            m2 (merge m {:_res res})]
        (if (= 0 (count (:title m)))
          (assoc m2 :title (file-title path))
          m2)))))

(defn try-parse
  "Try to parse a string s using parse-fn. If it fails, return nil"
  [parse-fn s]
  (try (parse-fn s) (catch Exception e)))

(def try-parseInt (partial try-parse #(Integer/parseInt %)))
;; TODO: test funcion (try-parseInt "12")

;; :creationdate Fri Dec 26 14:25:13 2014,
;; SS for milliseconds, ss for seconds.
(def fmtr-date-time-tz
  (tf/with-zone
    (tf/formatter "EEE MMM dd HH:mm:ss yyyy")
    (t/default-time-zone)))

;; TODO: maybe move to datetime.clj in lib.
(defn parse-date-time [datetime]
  (tf/parse fmtr-date-time-tz datetime))

;; TODO maybe need to try different formats, we'll see.
;; :creationdate Fri Dec 26 14:25:13 2014,
(def try-parse-date-time (partial try-parse parse-date-time))

;; TODO: test cases.
;; (try-parse-date-time "Fri Dec 26 14:25:13 2014")
;; (parse-date-time "Fri Dec 26 14:25:13 2014")

(defn insert-id
  "Return id from result of insert (seq of maps OR single map)"
  [res]
  (if (map? res)
    (:id res)
    (:id (first res))))

(defn path-format
  "Get format (eg pdf) from path, by removing . from extension of path."
  [path]
  (str/replace (fs/extension path) #"^." ""))

(defn apply-prepares-where
  "Apply prepares-fns to the where clause.
   Standard Korma does not do this, don't know why..."
  [table m]
  (if-let [preps (-> table :prepares seq)]
    (let [prep-fn (apply comp preps)]
      (prep-fn m))
    m))

;; deze versie door table als symbol/value mee te geven, dan geen (symbol (name)) nodig.
(defn select-insert!
  "select or insert a record from a table in a database.
   returns a map of the selected or inserted record, normally containing an :id key.
   All fields in map m must correspond to the database record to be selected.
   For now just use title field, with Korma this should be easier than with direct jdbc.
  table - :keyword"
  [table m]
  ;; TODO: this is a kind op upsert, this is possible in Postgres 9.5.
  (println m)
  (println (str table))
  (if-let [records (seq (select table
                                (where (apply-prepares-where table m))))]
    records
    (do
      (insert table (values m)))))

;; TODO: run for all items in actions table.
(defn insert-book-format-relfile!
  "Insert records for book, bookformat and relfile for path, update File.RelFile_id.
   Used for single files that are a book-format, like PDF's.
   Iff book with same title/author already exists, use this one."
  [path {:keys [title author pages creationdate] :as m}]
  (let [book-id (insert-id
                 (select-insert! book
                                 {:pubdate (try-parse-date-time creationdate)
                                  :title title
                                  :authors author
                                  :npages (try-parseInt pages)}))
        bookformat-id (insert-id
                       (select-insert! bookformat
                                       {:book_id book-id
                                        :format (path-format path)}))
        file-record (first (select :file
                            (fields :filesize :ts :ts_cet :md5)
                            (where {:fullpath path})))
        relfile-id (insert-id
                    (select-insert! relfile
                                    (merge file-record
                                           {:bookformat_id bookformat-id
                                            :relpath (fs/base-name path)
                                            :filename (fs/base-name path)
                                            :relfolder ""})))]
    (update file
            (set-fields {:relfile_id relfile-id})
            (where {:fullpath path}))))

(defn replace-0char
  "Replace a 0 char/byte in s by a space"
  [s]
  (clojure.string/replace s (char 0) \space))

(defn update-action!
  "Update action record with results"
  [id {:keys [exit out err]}]
  (update action
          (set-fields {:exec_ts (t/now)
                       :exec_output (replace-0char out)
                       :exec_stderr (replace-0char err)
                       :exec_status (if (= 0 exit) "ok" (str "error:" exit))})
          (where {:id id})))

(defn pdfinfo!
  "Exec pdfinfo on file and create RelFile, BookFormat and Book records.
   Also update action record with results."
  [{:keys [id fullpath_action]} opts]
  (let [{:keys [title author _res] :as m} (get-pdfinfo fullpath_action)]
    (println "Found authors and title: " author " - " title)
    (println "Whole map: " m)
    (if (:really opts)
      (do
        (transaction
         (insert-book-format-relfile! fullpath_action m)
         ;; TODO update action op generieke plek? Als alle actions een _res returnen?
         (update-action! id _res)
         ;;(rollback) ;; tijdelijk, tijdens debuggen vage file en update-action.
         ) 
        :keep) ;; TODO: want to keep the action with results, so do not delete!
      (println "Dry run, don't insert records: " fullpath_action))))

;; end of specific actions

(defn delete-action!
  "Delete action record from DB"
  [db-con id opts]
  (if (:really opts)
    (jdbc/delete! db-con :action ["id = ?" id])
    (println "Dry run, don't delete: " id)))

;; TODO: define actions with macro's?
(defn do-actions! 
  "do actions based on action field in file and action table"
  [db-con opts]
  (doseq [row (jdbc/query db-con "select * from action where exec_ts is null")]
    (if-let [result 
             (case (:action row)
               "delete" (delete-file! db-con (:fullpath_action row) opts)
               "mv" (move-file! db-con (:fullpath_other row) (:fullpath_action row) opts)
               "cp" (copy-file! db-con (:fullpath_other row) (:fullpath_action row) opts)
               "pdfinfo" (pdfinfo! row opts)
               nil)]
      (if (= :ok result)
        (delete-action! db-con (:id row) opts)))))

