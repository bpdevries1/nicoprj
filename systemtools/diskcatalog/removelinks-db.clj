#!/bin/bash lein-exec

; removelinks-db.clj - remove files from bigfiles.db that are symlinks or hardlinks.

(load-file "../../clojure/lib/def-libs.clj") 

; @todo async weg, maar eerst nog nodig met huidige functies.
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
  (let [cal-format (java.text.SimpleDateFormat. "yyyy-MM-dd hh:mm:ss")]
    (->> (find-files-nolink root-dir #".*")
         (filter #(> (fs/size %) treshold))
         (filter #(fs/file? %))
         (filter #(not (fs/link? %))
         (map #(hash-map :fullpath (str %)
                         :folder (fs/parent %)
                         :filename (fs/base-name %)
                         :filesize (fs/size %)
                         :ts_cet (.format cal-format (fs/mod-time %))))))))
  
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
            [:ts_cet "varchar"])))
    db-spec))

(defn remove-links 
  "remove records in db-spec for files that are links"
  [db-spec]
  (doseq [row (jdbc/query db-spec "select fullpath from file")]
    ; (println (str "row: " row))
    (when (fs/link? (:fullpath row))
      (println (str "delete from DB (link): " (:fullpath row)))
      (jdbc/delete! db-spec :file ["fullpath = ?" (:fullpath row)]))))

(def required-opts #{:database})

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
            ["-db" "--database" "Database path" :default "~/projecten/diskusage/bigfiles.db"]
            ["-r" "--root" "Root directory to find big files in"])]
  (if (or (:help opts)
          (missing-required? opts))
    (println banner)
    (do (println (str "opts: " opts ", remaining args: " args))
        (let [db-spec (create-db opts)]
          (remove-links db-spec))
        (println "Finished")))))

(main *command-line-args*)

