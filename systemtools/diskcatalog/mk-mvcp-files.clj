#!/bin/bash lein-exec

; calc-md5.clj

(load-file "../../clojure/lib/def-libs.clj")

(set-log4j! :level :info)

(deps '[[digest "1.4.4"]])
(require 'digest)

(load-file "lib-diskcat.clj")

(defn det-target
  "Determine target full filename based on specs and files found.
  Return a string with the full path."
  [sourcefullpath sourcespec_isfile sourcespec targetspec]
  (str
   (if (= 1 sourcespec_isfile)
     (if (fs/exists? targetspec)
       (if (fs/directory? targetspec)
         (fs/file targetspec (fs/base-name sourcefullpath))
         ;; else: existing but a file -> ERROR
         (str "ERROR: target file exists: " targetspec))
       ;; else: non-existing target: assume file
       targetspec)
     ;; else: based on sourcespec=dir:
     (path-target sourcefullpath sourcespec targetspec))))

(defn make-move-copy 
  "Make action records with move or copy action.
  These contain actions for individual files.
  fullpath_action will contain the target file, fullpath_other the source."
  [dbcon {:keys [sourcespec targetspec action really]}]
  (let [sql "select fullpath, 1 sourcespec_isfile from file
             where fullpath = ?
             union
             select fullpath, 0 sourcespec_isfile from file
             where fullpath like ?"
        path_like (path-add-perc sourcespec)
        cmdline (str action ":" sourcespec " => " targetspec)]
    (doseq [{:keys [fullpath sourcespec_isfile]} (jdbc/query dbcon [sql sourcespec path_like])]
      (let [targetfile (det-target fullpath sourcespec_isfile sourcespec targetspec)
            #_(str "TODO: sourcespec_isfile: " sourcespec_isfile)]
        (log/info (str action ": " fullpath " => " targetfile))
        (when really
          (jdbc/insert! dbcon :action {:fullpath_action targetfile
                                        :fullpath_other fullpath
                                        :action action
                                        :ts_cet (tc/to-sql-time (t/now))
                                        :notes cmdline}))))))

(defn main [args]
  (when-let [opts (my-cli args #{:dbspec :sourcespec :targetspec}
        ["-h" "--help" "Print this help" :default false :flag true]
        ["-d" "--dbspec" "Database spec/config/EDN file (postgres)" :default "~/.config/media/media.edn"]
        ["-s" "--sourcespec" "Source spec (dir or file)"]
        ["-t" "--targetspec" "Target spec (dir or file)"]
        ["-a" "--action" "mv or cp" :default "mv"]
        ["-r" "--really" "Really execute" :default false :flag true])]
    (let [db-spec (db-postgres (fs/expand-home (:dbspec opts)))]
      (jdbc/with-db-connection [db-con db-spec]
        (make-move-copy db-con opts)))))

(when (is-cmdline?)
  (main *command-line-args*))


