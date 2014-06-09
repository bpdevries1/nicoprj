#!/bin/bash lein-exec

(use '[leiningen.exec :only  (deps)])

; (deps '[[org.clojure/tools.logging "0.1.2"]])
(deps '[[clj-logging-config "1.9.10"]]) 

; deps voor deze clj-logging-config:
;    org.clojure/tools.logging 0.2.3
;    log4j 1.2.16

; in voorbeeld wel deze beide dingen ge-used.
(require '[clojure.tools.logging :refer :all])
(require '[clj-logging-config.log4j :refer :all])  
(require '[clojure.java.io :as io])

; (set-logger!)
; (info "Just a plain logging message")

;(set-logger! :pattern "%m%n")
;(info "Just the message this time")

(set-logger! :pattern "%d - %m%n")
(info "A logging message with the date in front")

(with-open [f (io/output-stream (io/file "job-123.log"))]
  (with-logging-config [:root {:level :debug :out f :pattern ">>> %d - %m %n"}]
    (logf :info "foo")))
; deze werkt, maar nogal omslachtig dus.

; uit http://www.paullegato.com/blog/logging-clojure-clj-logging-config/
(set-logger! :level :debug
                        :out (org.apache.log4j.FileAppender.
                              (org.apache.log4j.EnhancedPatternLayout. org.apache.log4j.EnhancedPatternLayout/TTCC_CONVERSION_PATTERN)
                              "foo.log"
                              true))

(info "This is a test log message.")

