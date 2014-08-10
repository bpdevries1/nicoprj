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
  [db-spec]
  (doseq [row (jdbc/query db-spec "select id, fullpath from file where md5 is null")]
    (log/info "Calculating MD5 sum for: " (:fullpath row))
    (jdbc/execute! db-spec ["update file set md5 = ? where id = ?" (file-md5 (:fullpath row)) (:id row)])))

(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskcatalog"]
        ["-db" "--database" "Database path" :default "~/projecten/diskcatalog/bigfiles.db"]
        ["-r" "--root" "Root directory to find big files in"])]
    (let [db-spec (db-spec-path db-spec-sqlite (:database opts))]
       (calc-md5! db-spec))))

(when (is-cmdline?)
  (main *command-line-args*))


