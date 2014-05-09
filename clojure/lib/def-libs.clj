; Load default clojure libraries for use in (single) Clojure script file.

(use '[leiningen.exec :only  (deps)])
(deps '[[me.raynes/fs "1.4.5"]]) ; file system utilities
(deps '[[org.clojure/tools.cli "0.2.4"]])

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
         '[clojure.tools.cli :refer [cli]])


