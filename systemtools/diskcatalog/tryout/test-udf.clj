#!/bin/bash lein-exec

; test-udf.clj

(load-file "../../clojure/lib/def-libs.clj")

(load-file "lib-diskcat.clj")

; (require 'some.UDF)
(require 'SqlRegExp)

(defn test-udf-1
  "Test SQLite user defined function"
  [db-spec]
  (jdbc/with-db-connection [db-con db-spec]
    (org.sqlite.Function/create (:connection db-con) "sqlregexp" (SqlRegExp.))
    (println (jdbc/query db-con "select sqlregexp('a.(..)', 'strabcd') col"))))        

(defn test-udf
  "Test SQLite user defined function"
  [db-spec]
  (jdbc/with-db-connection [db-con db-spec]
    (org.sqlite.Function/create (:connection db-con) "regexp" (SqlRegExp.))
    (println (jdbc/query db-con "select 1 res where regexp('a.(...)', 'strabcde') is not null"))))        

(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskcatalog"]
        ["-db" "--database" "Database path" :default "~/projecten/diskcatalog/bigfiles.db"]
        ["-r" "--root" "Root directory to find big files in"])]
    (let [db-spec (db-spec-path db-spec-sqlite (:database opts))]
       (test-udf db-spec))))

(main *command-line-args*)

