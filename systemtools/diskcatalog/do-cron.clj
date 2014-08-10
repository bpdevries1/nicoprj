#!/bin/bash lein-exec

; do-cron.clj - do actions that can be executed from a cron job.

(load-file "../../clojure/lib/def-libs.clj") 
(load-file "lib-diskcat.clj")
(load-file "calc-md5.clj")
(load-file "check-backups.clj")

(set-log4j! :level :debug)

; this main overrides in the ones in eg calc-md5.clj
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
         (calc-md5! db-con)
         (load-file (str (fs/file (fs/expand-home (:projectdir opts)) "path-specs.clj")))
         (check-backups db-con backup-defs (merge opts {:clear true}))))))

(when (is-cmdline?)
  (main *command-line-args*))

