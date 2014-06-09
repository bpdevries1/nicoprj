#!/bin/bash lein-exec

(use '[leiningen.exec :only  (deps)])

;(deps '[[org.clojure/tools.logging "0.1.2"]])
;(deps '[[org.clojure/tools.logging "0.3.1"]])

(deps '[[org.clojure/java.classpath "0.2.2"]])

;(require '[clojure.tools.logging :as log])

(require '[clojure.java.classpath :as cp])

(println (cp/classpath))

(println "Absolute paths:")
(println (map #(.getAbsolutePath %) (cp/classpath)))

(println "Names:")
(println (map #(.getName %) (cp/classpath)))

(println "Paths:")
(println (map #(.getPath %) (cp/classpath)))

; system-classpath is er niet.
;(println "Absolute paths from system-classpath:")
;(println (map #(.getAbsolutePath %) (cp/system-classpath)))



;
;(defn divide [x y]
;  (log/info "dividing" x "by" y)
;  (try
;    (log/spyf "result: %s" (/ x y)) ; yields the result
;    (catch Exception ex
;      (log/error ex "There was an error in calculation"))))
;
;(divide 1 2)
;
;(divide 2 0)

;(log/info "dividing" 1 "by" 2)



