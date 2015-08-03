#!/bin/bash lein-exec

; walk (complete) directory structure, find files bigger than treshold, put in sqlite/postgres DB.
; goal: further analysis, de-duplicate where possible.
; @todo later: also do on laptops, to find more duplicates.
; duplicates are not wrong per se, could be backups.
; also files on laptop might be gone any time...

; @todo nog kijken hoe het eruit ziet zonder async? dan for [file files] (insert! file)
;       wat voegt async dan toe, behalve leerzame ervaring?

(load-file "../../clojure/lib/def-libs.clj") 
(load-file "lib-diskcat.clj")

(deps '[[org.clojure/core.async "0.1.278.0-76b25b-alpha"]])
; [2014-05-04 14:49:26] onderstaande is huidige op https://github.com/clojure/core.async, maar geeft vage melding ivm memoize.
;(deps '[[org.clojure/core.async "0.1.301.0-deb34a-alpha"]])
(require '[clojure.core.async :as async :refer [>! <! >!! <!!]])

(defn insert-update-file! 
  "Check if the file already exists in database. If not, insert. If so, update"
  [db-con data]
  (if-let [db-data
           (first
            (jdbc/query db-con
                        ["select * from file where fullpath = ?" (:fullpath data)]))]
    (when-not (and (= (:filesize data) (:filesize db-data))
                   (= (:ts_cet data) (:ts_cet db-data)))
      (println "Updating file in DB: " (:fullpath data))
      (jdbc/execute! db-con
                     ["update file set md5=null, ts_cet = ?, filesize = ? where id = ?" 
                      (:ts_cet data) (:filesize data) (:id db-data)]))
    ; else
    (do
      (println "Inserting new file in DB: " (:fullpath data))
      (jdbc/insert! db-con :file (assoc data :goal (det-goal (:fullpath data)))))))

(defn database-consumer
  "Accept files-specs and put them in database"
  [db-con finish-chan]
  ; @note previously used sliding-buffer, which can cause messages to be lost. This should not happen with a standard buffer, then the put will block.
  (let [in (async/chan (async/buffer 64))]
      (async/go-loop []
           (if-let [data (<! in)]
             (do (println (format "database-consumer received data %s" data))
                 (insert-update-file! db-con data)
                 ; (jdbc/insert! db-con :file data)
                 ; (println "data inserted")
                 (recur))
             (do (println "data is nil, reading is done.")
                 (>! finish-chan :done))))
    in))

; @todo check if ts_cet is really a cet time, maybe ts/standard-time-zone is needed
(defn big-files
  "Determine big files in directory recursively. Treshold in bytes"
  [root-dir treshold]
  ;; @todo hh:mm:ss results in 12hour clock, need to do HH for 24 hour clock.
  ;; cannot do now, as old and new contents may conflict, files will not be determined as the same.
  ;; also check if ts_cet is really CET time.
  ;; and maybe add a field ts_utc. (compare keynote).
  ;; 2-8-2015 ts format was wrong, should use HH for hours (24h format), not hh (AM/PM is missed then)
  (let [;; cal-format (java.text.SimpleDateFormat. "yyyy-MM-dd HH:mm:ss")
        computer (computername)]
    (->> (find-files-nolink root-dir #".*")
         (filter #(> (fs/size %) treshold))
         (filter #(fs/file? %))
         (filter #(not (fs/link? %)))
         ;; for postgres more explicit conversion to string.
         (map #(hash-map :fullpath (str %)
                         :folder (str (fs/parent %))
                         :filename (str (fs/base-name %))
                         :filesize (fs/size %)
                         :computer computer
                         :ts (tc/to-sql-time (fs/mod-time %))
                         ;; use ts (real timestamp with TZ filed) now, not a varchar here.
                         ;; :ts_cet (.format cal-format (fs/mod-time %))
                         )))))
  
(defn bigfiles-producer
  "Produce messages and deliver them to consumers."
  [opts & channels]
  (async/go
   (doseq [file (big-files (:root opts) (:treshold opts))
           out  channels]
     (>! out file))
   (doseq [out channels]
     (async/close! out))))

(defn main [args]
  (when-let [opts (my-cli args #{:dbspec}
      ["-h" "--help" "Print this help"
            :default false :flag true]
      ["-t" "--treshold" "Treshold for big files in bytes" 
            :default 10e6 :parse-fn #(Float. %)]
      ;; ["-d" "--database" "Database path" :default "~/projecten/diskcatalog/bigfiles.db"]
      ["-d" "--dbspec" "Database spec/config/EDN file (postgres)" :default "~/.config/media/media.edn"]
      ["-s" "--pathspecs" "Path specs file" :default "path-specs-books.clj"]
      ["-z" "--deletedb" "Delete/zap DB before reading"
            :default false :flag true]
      ["-r" "--root" "Root directory to find big files in"])]
    (let [db-spec (db-postgres (fs/expand-home (:dbspec opts)))
          finish-chan (async/chan 1)]
      (load-file (str (fs/file (fs/expand-home (:projectdir opts)) (:pathspecs opts))))
       ; @todo kan zijn dat db-con niet goed werkt samen met async threads. Maar even zien.
      (jdbc/with-db-connection [db-con db-spec]
        ;; (org.sqlite.Function/create (:connection db-con) "regexp" (SqlRegExp.))
        (bigfiles-producer opts (database-consumer db-con finish-chan))
        (println (str "Result of reading finish-chan: " (<!! finish-chan)))))))

(main *command-line-args*)

