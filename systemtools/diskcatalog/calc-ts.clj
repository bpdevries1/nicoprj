#!/bin/bash lein-exec

; calc-md5.clj
;; 2-8-2015 temp script to add ts-fields (should be done in bigfiles2db.clj)

(load-file "../../clojure/lib/def-libs.clj")

(set-log4j! :level :info)

(load-file "lib-diskcat.clj")

; @todo delete path from exception message. Only keep everything between parens.
(defn file-ts
  "Calculate MD5 sum for path"
  [^String path]
  (let [linux-path (to-linux-path path)]
    (try 
      (fs/mod-time (fs/file linux-path))
      (catch java.io.IOException e (.getMessage e)))))

(defn calc-ts!
  "Calculate MD5 sum for files where md5 field is null"
  [db-con all?]
  (doseq [row (jdbc/query
               db-con
               (if all?
                 "select id, fullpath from file where ts is null"
                 "select id, fullpath from file where ts is null and action='ts'"))]
    (log/info "Calculating ts for: " (:fullpath row))
    (jdbc/execute! db-con ["update file set ts = ? where id = ?"
                           (tc/to-sql-time (file-ts (:fullpath row))) (:id row)])))

(defn main [args]
  (when-let [opts (my-cli args #{:dbspec}
        ["-h" "--help" "Print this help" :default false :flag true]
        ["-a" "--all" "Calc MD5 for all files (default: only when action=md5)"
         :default false :flag true]                  
        ["-d" "--dbspec" "Database spec/config/EDN file (postgres)" :default "~/.config/media/media.edn"])]
    (let [db-spec (db-postgres (fs/expand-home (:dbspec opts)))]
      (jdbc/with-db-connection [db-con db-spec]
        (calc-ts! db-con (:all opts))))))

(when (is-cmdline?)
  (main *command-line-args*))


