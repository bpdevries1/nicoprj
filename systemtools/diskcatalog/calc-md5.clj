#!/bin/bash lein-exec

; calc-md5.clj

(load-file "../../clojure/lib/def-libs.clj")

(set-log4j! :level :info)

(deps '[[digest "1.4.4"]])
(require 'digest)

(load-file "lib-diskcat.clj")

; @todo delete path from exception message. Only keep everything between parens.
(defn file-md5
  "Calculate MD5 sum for path"
  [^String path]
  (let [linux-path (to-linux-path path)]
    (try 
      (digest/md5 (fs/file linux-path))
      (catch java.io.IOException e (.getMessage e)))))

(defn calc-md5!
  "Calculate MD5 sum for files where md5 field is null"
  [db-con all?]
  (doseq [row (jdbc/query
               db-con
               (if all?
                 "select id, fullpath from file where md5 is null"
                 "select id, fullpath from file where md5 is null and action='md5'"))]
    (log/info "Calculating MD5 sum for: " (:fullpath row))
    (jdbc/execute! db-con ["update file set md5 = ? where id = ?" (file-md5 (:fullpath row)) (:id row)])))

(defn main [args]
  (when-let [opts (my-cli args #{:dbspec}
        ["-h" "--help" "Print this help" :default false :flag true]
        ["-a" "--all" "Calc MD5 for all files (default only when action=md5)"
         :default false :flag true]                  
        ["-d" "--dbspec" "Database spec/config/EDN file (postgres)" :default "~/.config/media/media.edn"])]
    (let [db-spec (db-postgres (fs/expand-home (:dbspec opts)))]
      (jdbc/with-db-connection [db-con db-spec]
        (calc-md5! db-con (:all opts))))))

(when (is-cmdline?)
  (main *command-line-args*))


