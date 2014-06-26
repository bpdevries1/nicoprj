#!/bin/bash lein-exec

; delete-empty-dirs.clj - delete empty dirs from filesystem. Some empty dirs in /media/nas/install.

(load-file "../../clojure/lib/def-libs.clj") 
(load-file "lib-diskcat.clj")

(defn delete-empty-dirs!
  [dir really]
  (let [empty-subs
    (->> (fs/walk (fn [root dirs files]
           (when (and (empty? dirs) (empty? files)) root)) dir)
         (filter (complement nil?)))]
    (doseq [subdir empty-subs]
      (println "delete empty dir: " subdir)
      (when really
        (fs/delete subdir)
        ; @todo should recur on parent only after all subdirs have been handled, with another doseq
        ; currently some double checks, less efficient.
        (println "and recur on: " (fs/parent subdir))
        (delete-empty-dirs! (fs/parent subdir) really)))))

(defn main [args]
  (when-let [opts (my-cli args #{:dir}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-d" "--dir" "Directory"]
        ["-r" "--really" "Really do delete actions. Otherwise dry run" :default false :flag true])]
     (delete-empty-dirs! (:dir opts) (:really opts))))

(main *command-line-args*)


