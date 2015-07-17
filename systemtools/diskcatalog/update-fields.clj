#!/bin/bash lein-exec

; update-fields.clj

(load-file "../../clojure/lib/def-libs.clj") 
(load-file "lib-diskcat.clj")

(set-log4j! :level :info)

; 13-7-2014 unused now.
(defn sql-op
  "Return SQL operator based on like-exp: string->like, regexp->regexp"
  [expr]
  (cond (= (type expr) java.lang.String) "like"
        (= (type expr) java.util.regex.Pattern) "regexp"))

(defn update-spec-path-1!
  "Update DB field based on specific like/regular expr."
  [db-con field-name field-value like-exp]
  (cond 
    (= (type like-exp) java.lang.String)
    (jdbc/execute! db-con
      [(str "update file set " field-name " = ? where fullpath like ? and " field-name " is null") 
          field-value like-exp])          
    (= (type like-exp) java.util.regex.Pattern)
    (jdbc/execute! db-con
      [(str "update file set " field-name " = ? where regexp(?, fullpath) is not null and " field-name " is null") 
          field-value (str like-exp)])))

(defn update-spec-path!
  "Update DB fields based on db-spec-path. Only set fields which are currently null"
  [db-con path-specs]
  (doseq [[field-name value-spec] (seq path-specs)]
    (doseq [[field-value like-exps] (seq value-spec)]
      (doseq [like-exp like-exps]
        (log/info "Update file: field = " field-name ", new value = " field-value ", path ~= " like-exp)
        (update-spec-path-1! db-con field-name field-value like-exp)))))

(defn mark-srcbak!
  "Mark srcbak field with either source or backup"
  [db-con value path]
  (jdbc/execute! db-con
    ["update file set srcbak = ?
      where srcbak is null
      and fullpath like ?"
     value (path-add-perc path)]))

(defn update-srcbak!
  "update srcbak field based on backup-defs"
  [db-con backup-defs opts]
  (doseq [[backupname {:keys [paths-file ignore-file target-path skip-src]}] (seq backup-defs)]
    (log-exprs paths-file ignore-file target-path)
    (let [cache-dir (fs/file (fs/expand-home (:projectdir opts)) ".backupdef-cache" backupname)
          paths ((make-cacheable read-paths cache-dir) paths-file)]
      (log-exprs cache-dir paths)
      (doseq [path paths]
        (mark-srcbak! db-con "source" path))
      (mark-srcbak! db-con "backup" target-path))))

(defn update-fields!
  "Update fields that were added after DB was created"
  [db-con path-specs backup-defs opts]
  (jdbc/execute! db-con ["update file set computer = ? where computer is null" (computername)])
  (update-spec-path! db-con path-specs)
  ;; 29-6-2015 NdV srcbak niet meer doen, nu helemaal door Unison geregeld.
  #_(update-srcbak! db-con backup-defs opts))

(def path-specs) ; placeholder
(def backup-defs) ; placeholder

(defn load-sqlite-extension
  "load regexp functionality"
  [db-spec]
  (jdbc/query db-spec "SELECT load_extension('/usr/lib/sqlite3/pcre.so')"))

(defn main [args]
  (when-let [opts (my-cli args #{:dbspec}
        ["-h" "--help" "Print this help" :default false :flag true]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskcatalog"]
        ["-s" "--pathspecs" "Path specs file" :default "path-specs-books.clj"]
        ["-d" "--dbspec" "Database spec/config/EDN file (postgres)" :default "~/.config/media/media.edn"])]
    (let [db-spec (db-postgres (fs/expand-home (:dbspec opts)))]
      (load-file (str (fs/file (fs/expand-home (:projectdir opts)) (:pathspecs opts))))
      (println path-specs)
      (jdbc/with-db-connection [db-con db-spec]
        #_(org.sqlite.Function/create (:connection db-con) "regexp" (SqlRegExp.))
        (update-fields! db-con path-specs backup-defs opts)))))

(when (is-cmdline?)
  (main *command-line-args*))

