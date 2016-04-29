;; 6-4-2016 NdV deze versie al stuk 'beter' dan versie in diskcatalog, o.a. door gebruik Korma.

;; (load-file "../../clojure/lib/def-libs-p.clj")

;; 8-4-2016 werkt het nog zonder load-file?
;; (load-file "../../cljlib/cmdline/def-libs-p.clj")
;; (load-file "lib-diskcat.clj")

;; TODO: zowel voor Korma als entities namespaces weer require :as gebruiken ipv :refer :all. Kijken of dit werkt, want eerder wat vage dingen gehad.
;; TODO: functies verplaatsen naar helper/lib namespaces.
;; TODO: query dingen met Korma doen.
;; TODO: Meeste dingen naar controller en/of model namespace, zodat je ook vanuit GUI kan aanroepen.

;;(use 'korma.db 'korma.core)

(require '[clojure.java.jdbc :as jdbc]
        ;; '[clj-time.core :as t]
        ;; '[clj-time.coerce :as tc]
        ;; '[clj-time.format :as tf]
         '[me.raynes.fs :as fs]
        ;; '[libndv.core :as h]
        ;; '[libndv.coerce :refer [to-float to-int to-key]]
        ;; '[libndv.debug :as dbg]
        ;; '[mediaweb.models.entities :refer :all]
         '[mediaweb.util.file :refer :all]) ;; :all mogelijk nog eens vervangen.


(defn main [args]
  (when-let [opts (my-cli args #{:dbspec}
                          ["-h" "--help" "Print this help"
                           :default false :flag true]
                          ["-d" "--dbspec" "Database spec/config/EDN file (postgres)"
                           :default "~/.config/media/media.edn"]
                          ["-p" "--projectdir" "Project directory"
                           :default "~/projecten/diskcatalog"]
                          ["-s" "--pathspecs" "Path specs file"
                           :default "path-specs-books.clj"]
                          ["-r" "--really" "Really do delete actions. Otherwise dry run"
                           :default false :flag true])]
    (let [db-spec (db-postgres (fs/expand-home (:dbspec opts)))]
      (load-file (str (fs/file (fs/expand-home (:projectdir opts)) (:pathspecs opts))))
      (defdb db db-spec)
      (jdbc/with-db-connection [db-con db-spec]
        (do-actions! db-con opts))))
  (System/exit 0))

