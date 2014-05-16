#!/bin/bash lein-exec

; update-fields.clj

(load-file "../../clojure/lib/def-libs.clj") 

(defn update-spec-path!
  "Update DB fields based on db-spec-path. Only set fields which are currently null"
  [db-spec path-specs]
  (doseq [[field-name value-spec] (seq path-specs)]
    (doseq [[field-value like-exps] (seq value-spec)]
      (doseq [like-exp like-exps]
        (log/info "Update file: field = " field-name ", new value = " field-value ", path = " like-exp)
        (jdbc/execute! db-spec
        ;(println  
          [(str "update file set " field-name " = ? where fullpath like ? and " field-name " is null") field-value like-exp]))))) 

(defn update-fields!
  "Update fields that were added after DB was created"
  [db-spec path-specs]
  (jdbc/execute! db-spec ["update file set computer = ? where computer is null" (computername)])
  (update-spec-path! db-spec path-specs))

(def path-specs) ; placeholder

(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskusage"]
        ["-db" "--database" "Database path" :default "~/projecten/diskusage/bigfiles.db"])]
    (let [db-spec (db-spec-path db-spec-sqlite (:database opts))]
       (load-file (str (fs/file (fs/expand-home (:projectdir opts)) "path-specs.clj")))
       (println path-specs)
       (update-fields! db-spec path-specs))))

(main *command-line-args*)

