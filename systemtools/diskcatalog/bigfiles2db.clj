#!/bin/bash lein-exec

; walk (complete) directory structure, find files bigger than treshold, put in sqlite DB.
; goal: further analysis, de-duplicate where possible.
; @todo later: also do on laptops, to find more duplicates.
; duplicates are not wrong per se, could be backups.
; also files on laptop might be gone any time...

; @todo nog kijken hoe het eruit ziet zonder async? dan for [file files] (insert! file)
;       wat voegt async dan toe, behalve leerzame ervaring?

(load-file "../../clojure/lib/def-libs.clj") 

(deps '[[org.clojure/core.async "0.1.278.0-76b25b-alpha"]])
; [2014-05-04 14:49:26] onderstaande is huidige op https://github.com/clojure/core.async, maar geeft vage melding ivm memoize.
;(deps '[[org.clojure/core.async "0.1.301.0-deb34a-alpha"]])
(require '[clojure.core.async :as async :refer [>! <! >!! <!!]])

(defn database-consumer
  "Accept messages and pass them to web browsers via SSE."
  [db-spec finish-chan]
  (let [in (async/chan (async/sliding-buffer 64))]
      (async/go-loop []
           (if-let [data (<! in)]
             (do (println (format "database-consumer received data %s" data))
                 (jdbc/insert! db-spec :file data)
                 (println "data inserted")
                 ; (<! (async/timeout 1000))
                 ; (>! finish-chan :onedone)
                 (recur))
             (do (println "data is nil, reading is done.")
                 (>! finish-chan :done))))
    in))

; onderstaande 3 functies in lib zetten.
(defn file-seq-nolink
  "A tree seq on java.io.Files without following symlinks"
  {:added "1.0"
   :static true}
  [dir]
    (tree-seq
     (fn [^java.io.File f] (and (. f (isDirectory)) (not (fs/link? f)))) 
     (fn [^java.io.File d] (seq (. d (listFiles))))
     dir))

(defn find-files-nolink*
  "Find files in path by pred."
  [path pred]
  (filter pred (-> path fs/file file-seq-nolink)))

(defn find-files-nolink
  "Find files matching given pattern."
  [path pattern]
  (find-files-nolink* path #(re-matches pattern (.getName %))))
; einde lib-functies


; find-files en file-seq zijn recursive? in fs/ namespace.
(defn big-files
  "Determine big files in directory recursively. Treshold in bytes"
  [root-dir treshold]
  (let [cal-format (java.text.SimpleDateFormat. "yyyy-MM-dd hh:mm:ss")
        computer (computername)]
    (->> (find-files-nolink root-dir #".*")
         (filter #(> (fs/size %) treshold))
         (filter #(fs/file? %))
         (filter #(not (fs/link? %)))
         (map #(hash-map :fullpath (str %)
                         :folder (fs/parent %)
                         :filename (fs/base-name %)
                         :filesize (fs/size %)
                         :computer computer
                         :ts_cet (.format cal-format (fs/mod-time %)))))))
  
; this one doesn't work in a script: script exits before this task even starts.
; so either do the producing in the main thread or have some way to wait for everything to finish.
; could be that with producer2/consumer combination, the script exits before all consumers are done.
; this is indeed what happens.
(defn bigfiles-producer
  "Produce messages and deliver them to consumers."
  [opts & channels]
  (async/go
   (doseq [file (big-files (:root opts) (:treshold opts))
           out  channels]
     ; (<! (async/timeout 100))
     (>! out file))
   (doseq [out channels]
     (async/close! out))))

(def db-spec-sqlite {:classname "org.sqlite.JDBC"
                     :subprotocol "sqlite"})

(defn create-db
  "Create bigfile database based on opts. If db file exists, assume table exists"
  [opts]
    (let [db-path (fs/expand-home (:database opts))
          db-spec (assoc db-spec-sqlite :subname db-path)]
      (if (:deletedb opts)
        (fs/delete db-path))
      (println (str "db-spec: " db-spec))
      (if (fs/exists? db-path)
        (println (str "database already exists: " db-path))
        ; else: commands automatically in a transaction.
        (jdbc/db-do-commands db-spec
          "drop table if exists file"
          (jdbc/create-table-ddl :file
            [:id "integer primary key"]
            [:fullpath "varchar"]
            [:folder "varchar"]
            [:filename "varchar"]
            [:filesize "integer"]
            [:ts_cet "varchar"]
            [:md5 "varchar"]
            [:goal "varchar"]
            [:importance "varchar"]
            [:computer "varchar"]
            [:srcbak "varchar"]
            [:action "varchar"])))
    db-spec))

(def required-opts #{:root})

(defn missing-required?
  "Returns true if opts is missing any of the required-opts"
  [opts]
  (not-every? opts required-opts))

(defn main [args]
  ; args contains scriptname as first item, don't give to 'cli'
  (println "Started")
  (let [[opts args banner] (cli (rest args)
            ["-h" "--help" "Print this help"
                  :default false :flag true]
            ["-t" "--treshold" "Treshold for big files in bytes" 
                  :default 10e6 :parse-fn #(Float. %)]
            ["-db" "--database" "Database path" :default "~/projecten/diskusage/bigfiles.db"]
            ["-d" "--deletedb" "Delete DB before reading"
                  :default false :flag true]
            ["-r" "--root" "Root directory to find big files in"])]
  (if (or (:help opts)
          (missing-required? opts))
    (println banner)
    (do (println (str "opts: " opts ", remaining args: " args))
        (let [db-spec (create-db opts)
              finish-chan (async/chan 1)]
          (bigfiles-producer opts (database-consumer db-spec finish-chan))
          (println (str "Result of reading finish-chan: " (<!! finish-chan))))
        (println "Finished")))))

(main *command-line-args*)

