; Load default clojure libraries for use in (single) Clojure script file.

(use '[leiningen.exec :only  (deps)])
(deps '[[me.raynes/fs "1.4.5"]]) ; file system utilities

(require '[clojure.java.io :as io])

;(import 'java.util.Date)
;(import 'java.io.File)
; (import 'java.nio.file.Files) ; -> faalt: dingen in classpath erbij, nieuwe JVM? idd, java 7 nodig, maar nu eerst fs 1.4.5 doet het ook.

(require '[clojure.java.io :as io] 
         '[clojure.string :as str]
         '[me.raynes.fs :as fs]) 

