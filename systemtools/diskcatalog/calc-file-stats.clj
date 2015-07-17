#!/bin/bash lein-exec

; calc-file-stats.clj - Calculate statistics about contents of file table.

; @todo also count how many results the check-queries give, eg double files.

(load-file "../../clojure/lib/def-libs.clj") 
(load-file "lib-diskcat.clj")

; @todo remove this function, is also in create-tables.clj
(defn create-stats-table-sqlite-old!
  "Create stats table iff it does not exist yet"
  [db-spec]
  (if (= 0 (count (jdbc/query db-spec "select name from sqlite_master where type='table' and name = 'stats'")))
    (jdbc/db-do-commands db-spec
      (jdbc/create-table-ddl :stats
            [:id "integer primary key"]
            ; [:ts_cet "varchar"]
            [:ts_cet "TEXT DEFAULT (strftime('%Y-%m-%d %H:%M:%S','now', 'localtime'))"]
            [:nfiles "integer"]
            [:ngbytes "float"]
            [:ngoal "integer"]
            [:nimportance "integer"]
            [:nsrcbak "integer"]
            [:naction "integer"]
            [:notes "varchar"]))))

(defn count-not-null
  "Count records in file table which have fieldname not null"
  [db-spec fieldname]
  (-> (jdbc/query db-spec (str "select count(*) n from file where " fieldname " is not null"))
      first
      :n))

(defn calc-file-stats!
  "Calculate statistics about contents of file table."
  [db-spec opts]
  #_(create-stats-table! db-spec)
  (jdbc/insert! db-spec :stats 
    {:nfiles (count-not-null db-spec "fullpath")
     :ngbytes (-> (jdbc/query db-spec "select sum(filesize)/1000000000 ngbytes from file") first :ngbytes)
     :ngoal (count-not-null db-spec "goal")
     :nimportance (count-not-null db-spec "importance")
     :nsrcbak (count-not-null db-spec "srcbak")
     :naction (count-not-null db-spec "action")
     :ts_cet (tc/to-sql-time (t/now))
     :notes (:notes opts)}))
  
(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ;; ["-d" "--database" "Database path" :default "~/projecten/diskcatalog/bigfiles.db"]
        ["-d" "--dbspec" "Database spec/config/EDN file (postgres)" :default "~/.config/media/media.edn"]
        ["-n" "--notes" "Notes" :default "No comment"])]
    (let [db-spec-sqlite (db-spec-path db-spec-sqlite (:database opts))
          db-spec (db-postgres (fs/expand-home (:dbspec opts)))]
       (calc-file-stats! db-spec opts))))

(main *command-line-args*)

