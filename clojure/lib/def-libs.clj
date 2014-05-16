; Load default clojure libraries for use in (single) Clojure script file.

; @todo make namespace

(use '[leiningen.exec :only  (deps)])
(deps '[[me.raynes/fs "1.4.5"]]) ; file system utilities
(deps '[[org.clojure/tools.cli "0.2.4"]
        [com.taoensso/timbre "2.7.1"]]) ; 3.2.0 is newest [2014-05-11 20:42:12] but gives error message.

; use newest jdbc by defailt, has incompatbile changes from 0.2.3 to 0.3.0.
(deps '[[org.clojure/java.jdbc "0.3.3"]
        [org.xerial/sqlite-jdbc "3.7.2"]]) ; 3.7.2 lijkt nog wel de nieuwste ([2014-05-03 22:39:14])

; orig, working:
;(deps '[[org.clojure/java.jdbc "0.1.1"]
;        [org.xerial/sqlite-jdbc "3.7.2"]])

(require '[clojure.java.io :as io] 
         '[clojure.string :as str]
         '[me.raynes.fs :as fs]
         '[clojure.java.jdbc :as jdbc]
         '[clojure.tools.cli :refer [cli]]
         '[taoensso.timbre :as log])


; 11-05-2014 for now define some extra functions, later put in (ndv?) lib.

; see http://rosettacode.org/wiki/Hostname#Clojure 
(defn computername
  "Get computername, works both on windows and linux"
  []
  (.. java.net.InetAddress getLocalHost getHostName))

; SQLite database related:
(def db-spec-sqlite {:classname "org.sqlite.JDBC"
                     :subprotocol "sqlite"})

(defn db-spec-path
  "Create db-spec based on template and path"
  [db-spec db-path]
  (assoc db-spec :subname (fs/expand-home db-path)))

(defn missing-required?
  "Returns true if opts is missing any of the required-opts"
  [opts required-opts]
  (not-every? opts required-opts))

(defn my-cli
  "Wrapper around cli function in clojure.tools.cli. Return nil if not parsed correctly, also print banner then"
  [args required-opts & specs]
  (let [[opts args banner] (apply cli (rest args) specs)]
    (if (or (:help opts)
            (missing-required? opts required-opts))
      (println banner) ; also returns nil
      opts)))  

