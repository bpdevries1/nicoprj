#!/bin/bash lein-exec

; create-tables.clj - Create tables if not exists already in database.

(load-file "../../clojure/lib/def-libs.clj") 
(load-file "lib-diskcat.clj")

(defn table-exists-sqlite?
  "Return true if table already exists in db-spec. table is a :keyword"
  [db-spec table]
  (= 1 (count (jdbc/query db-spec
                          (str "select name from sqlite_master where type='table' and name = '" (name table) "'")))))

(defn table-exists?
  "Return true if table already exists in db-spec. table is a :keyword.
   For postgres return false for the moment."
  [db-spec table]
  false)

(defn create-table
  "Create table if not exists yet. table is a :keyword."
  [db-spec table & specs]
  (if-not (table-exists? db-spec table)
    (jdbc/db-do-commands db-spec
      (apply jdbc/create-table-ddl table specs))))

; @todo index-creation more DRY.
(defn create-tables
  "Create tables if not exist yet"
  [db-spec opts]
  (let [file-db-spec [[:id "serial"]
    [:fullpath "varchar"]
    [:folder "varchar"]
    [:filename "varchar"]
    [:filesize "int"]
    [:ts_cet "varchar"]
    [:md5 "varchar"]
    [:goal "varchar"]
    [:importance "varchar"]
    [:computer "varchar"]
    [:srcbak "varchar"]
    [:action "varchar"]]]
    (apply create-table db-spec :file file-db-spec)
    (apply create-table db-spec :file_deleted file-db-spec))
  ;; drop index if exists ix_file_1 -> this does work in Postgres
  ;; create index if not exists ix_file_1 on file (filesize) -> does not work in postgres
  (jdbc/db-do-commands db-spec
    "create index ix_file_1 on file (filesize)"
    "create index ix_file_2 on file (filename)"
    "create index ix_file_deleted_1 on file_deleted (filesize)"
    "create index ix_file_deleted_2 on file_deleted (filename)")
  (let [ts_cet_spec_sqlite "TEXT DEFAULT (strftime('%Y-%m-%d %H:%M:%S','now', 'localtime'))"
        ts_cet_spec "TIMESTAMP"]
    (create-table db-spec :stats 
      [:id "serial"]
      [:ts_cet ts_cet_spec]
      [:nfiles "int"]
      [:ngbytes "numeric"]
      [:ngoal "int"]
      [:nimportance "int"]
      [:nsrcbak "int"]
      [:naction "int"]
      [:notes "varchar"])
    ; [2014-07-13 13:51:13] action is obsolete, now have a WFM system.
    (create-table db-spec :action
      [:id "serial"] ; 9-6-2014 blijkbaar hierdoor ook een auto-gen veld.
      [:ts_cet ts_cet_spec]
      [:action "varchar"]
      [:fullpath_action "varchar"]
      [:fullpath_other "varchar"]
      [:notes "varchar"])
    (create-table db-spec :srcbak
      [:id "serial"]
      [:ts_cet ts_cet_spec]
      [:id_src "int"]
      [:id_bak "int"]
      [:fullpath_src "varchar"]
      [:fullpath_bak "varchar"]
      [:ts_cet_src "varchar"]
      [:ts_cet_bak "varchar"]
      [:filesize_src "int"]
      [:filesize_bak "int"]
      [:md5_src "varchar"]
      [:md5_bak "varchar"])
    (jdbc/db-do-commands db-spec
      "create index ix_srcbak1 on srcbak (fullpath_src)"
      "create index ix_srcbak2 on srcbak (fullpath_bak)")
    (create-table db-spec :fileinfo
      [:id "serial"]
      [:ts_cet ts_cet_spec]
      [:file_id "int"]
      [:fullpath "varchar"]
      [:name "varchar"]
      [:value "varchar"]
      [:notes "varchar"])
    (jdbc/db-do-commands db-spec
      "create index ix_fileinfo1 on fileinfo (file_id)"
      "create index ix_fileinfo2 on fileinfo (fullpath)")
    (create-table db-spec :filelog
      [:id "serial"]
      [:ts_cet ts_cet_spec]
      [:file_id "int"]
      [:fullpath "varchar"]
      [:action "varchar"]
      [:notes "varchar"]
      [:oldstatus "varchar"]
      [:newstatus "varchar"])
    (jdbc/db-do-commands db-spec
      "create index ix_filelog1 on filelog (file_id)"
      "create index ix_filelog2 on filelog (fullpath)")
    (create-table db-spec :filestatus
      [:id "serial"]
      [:ts_cet ts_cet_spec]
      [:file_id "int"]
      [:fullpath "varchar"]
      [:status "varchar"]
      [:notes "varchar"])
    (jdbc/db-do-commands db-spec
      "create index ix_filestatus1 on filestatus (file_id)"
      "create index ix_filestatus2 on filestatus (fullpath)")
    (jdbc/db-do-commands db-spec
      "create view file_with_status as
       select f.*, fs.status
       from file f
       left join filestatus fs on fs.file_id = f.id")))

;; TODO read db specs from file not in source control.
(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
;;        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskcatalog"]
        ["-d" "--dbspec" "Database spec/config/EDN file (postgres)" :default "~/.config/media/media.edn"])]
    #_(let [db-spec (db-spec-path db-spec-sqlite (:database opts))]
        (create-tables db-spec opts))
    (let [db-spec (db-postgres (fs/expand-home (:dbspec opts)))]
      (create-tables db-spec opts))))

(main *command-line-args*)

