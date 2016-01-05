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
    (println "Dry run, don't delete: " path))
  :ok)

(declare path-specs)

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
    (println "Dry run, don't move: " source-path))
  :ok)

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
      (let [m (apply merge (map line->map (str/split (:out res) #"\n")))]
        (if (= 0 (count (:title m)))
          (assoc m :title (file-title path))
          m)))))



(defn try-parse
  "Try to parse a string s using parse-fn. If it fails, return nil"
  [parse-fn s]
  (try (parse-fn s) (catch Exception e)))

(def try-parseInt (partial try-parse #(Integer/parseInt %)))

;; (try-parseInt "12")

(defn insert-id
  "Return id from result of insert (seq of maps)"
  [res]
  (:id (first res)))

(defn path-format
  "Get format (eg pdf) from path, by removing . from extension of path."
  [path]
  (str/replace (fs/extension path) #"^." ""))

(defn select-insert!
  "select or insert a record from a table in a database.
   returns a map of the selected or inserted record, normally containing an :id key.
   All fields in map m must correspond to the database record to be selected.
   For now just use title field, with Korma this should be easier than with direct jdbc."
  [db-con table m]
  (if-let [rec
           (seq (jdbc/query db-con
                            [(str "SELECT * FROM " (name table) " where title = ?")
                             (:title m)]))]
    rec
    (jdbc/insert! db-con table m)))

;; TODO: copy fields from File to RelFile.
;; TODO: creationDate parsing.
;; TODO: also check for bookformat and relfile if they already exist.
(defn insert-book-format-relfile!
  "Insert records for book, bookformat and relfile for path, update File.RelFile_id.
   Used for single files that are a book-format, like PDF's.
   Iff book with same title/author already exists, use this one."
  [db-con path {:keys [title author pages creationdate] :as m}]
  (let [book-id (insert-id (select-insert! db-con :book {:pubdate nil ;; TODO creationdate
                                                         :title title
                                                         :authors author
                                                         :npages (try-parseInt pages)}))
        ;; TODO bookformat also with select-insert!
        bookformat-id (insert-id (jdbc/insert! db-con :bookformat {:book_id book-id
                                                                   :format (path-format path)}))
        ;; TODO relfile also with select-insert!
        relfile-id (insert-id (jdbc/insert! db-con :relfile {:bookformat_id bookformat-id
                                                             :relpath (fs/base-name path)
                                                             :filename (fs/base-name path)
                                                             :relfolder ""}))]
    (jdbc/update! db-con :file {:relfile_id relfile-id} ["fullpath = ?" path])))

(defn pdfinfo!
  "Exec pdfinfo on file and create RelFile, BookFormat and Book records"
  [db-con source-path opts]
  (let [{:keys [title author] :as m} (get-pdfinfo source-path)]
    (println "Found authors and title: " author " - " title)
    (println "Whole map: " m)
    (if (:really opts)
      (do
        (insert-book-format-relfile! db-con source-path m)
        :todo)
      (println "Dry run, don't insert records: " source-path))))

;; end of specific actions

(defn delete-action!
  "Delete action record from DB"
  [db-con id opts]
  (if (:really opts)
    (jdbc/delete! db-con :action ["id = ?" id])
    (println "Dry run, don't delete: " id)))

(defn do-actions! 
  "do actions based on action field in file and action table"
  [db-con opts]
  (doseq [row (jdbc/query db-con "select * from action limit 1")]
    (if-let [result 
             (case (:action row)
               "delete" (delete-file! db-con (:fullpath_action row) opts)
               "mv" (move-file! db-con (:fullpath_other row) (:fullpath_action row) opts)
               "cp" (copy-file! db-con (:fullpath_other row) (:fullpath_action row) opts)
               "pdfinfo" (pdfinfo! db-con (:fullpath_action row) opts)
               nil)]
      (if (= :ok result)
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


