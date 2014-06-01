#!/bin/bash lein-exec

; update-fields.clj

(load-file "../../clojure/lib/def-libs.clj") 

(defn sql-op
  "Return SQL operator based on like-exp: string->like, regexp->regexp"
  [expr]
  (cond (= (type expr) java.lang.String) "like"
        (= (type expr) java.util.regex.Pattern) "regexp"))

(defn update-spec-path!-old
  "Update DB fields based on db-spec-path. Only set fields which are currently null"
  [db-con path-specs]
  (doseq [[field-name value-spec] (seq path-specs)]
    (doseq [[field-value like-exps] (seq value-spec)]
      (doseq [like-exp like-exps]
        (log/info "Update file: field = " field-name ", new value = " field-value ", path ~= " like-exp)
        ;(jdbc/execute! db-con
        (println  
          ; [(str "update file set " field-name " = ? where fullpath like ? and " field-name " is null") field-value like-exp]))))) 
         [(str "update file set " field-name " = ? where fullpath " (sql-op like-exp) " ? and " field-name " is null") field-value (str like-exp)])))))

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

(defn update-fields!
  "Update fields that were added after DB was created"
  [db-con path-specs]
  (jdbc/execute! db-con ["update file set computer = ? where computer is null" (computername)])
  (update-spec-path! db-con path-specs))

(def path-specs) ; placeholder

(defn load-sqlite-extension
  "load regexp functionality"
  [db-spec]
  (jdbc/query db-spec "SELECT load_extension('/usr/lib/sqlite3/pcre.so')"))

(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskcatalog"]
        ["-db" "--database" "Database path" :default "~/projecten/diskcatalog/bigfiles.db"])]
    (let [db-spec (db-spec-path db-spec-sqlite (:database opts))]
       (load-file (str (fs/file (fs/expand-home (:projectdir opts)) "path-specs.clj")))
       ;(load-sqlite-extension db-spec)
       (println path-specs)
       ;(update-fields! db-spec path-specs))))
       (jdbc/with-db-connection [db-con db-spec]
         (org.sqlite.Function/create (:connection db-con) "regexp" (SqlRegExp.))
         (update-fields! db-con path-specs)))))

(main *command-line-args*)

