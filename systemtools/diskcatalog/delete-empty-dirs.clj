#!/bin/bash lein-exec

; delete-empty-dirs.clj - delete empty dirs from filesystem. Some empty dirs in /media/nas/install.

(load-file "../../clojure/lib/def-libs.clj") 
(load-file "lib-diskcat.clj")

(defn delete-empty-dirs!
  [dir really iter]
  ;; walk function already works recursively.
  (let [empty-subs
        (->> (fs/walk (fn [root dirs files]
                        (when (and (empty? dirs) (empty? files)) root)) dir)
             (filter (complement nil?)))]
    (doseq [subdir empty-subs]
      (println "delete empty dir: " subdir)
      (when really
        (fs/delete subdir)))
    (when really ; only recur if really deleting, otherwise infinite loop.
      (when-not (empty? empty-subs)
        (println "Still have empty subs, so try again, iter = " (+ 1 iter))
        (recur dir really (+ 1 iter))))))

(defn main [args]
  (when-let [opts (my-cli args #{:dir}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-d" "--dir" "Directory"]
        ["-r" "--really" "Really do delete actions. Otherwise dry run" :default false :flag true])]
     (delete-empty-dirs! (:dir opts) (:really opts) 1)))

(main *command-line-args*)


