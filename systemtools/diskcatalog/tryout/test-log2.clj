#!/bin/bash lein-exec

(use '[leiningen.exec :only  (deps)])

;(deps '[[org.clojure/tools.logging "0.1.2"]])
(deps '[[org.clojure/tools.logging "0.3.0"]])

;(deps '[[log4j "1.2.17"]])
(deps '[[log4j/log4j "1.2.17" :exclusions [javax.mail/mail
                                           javax.jms/jms
                                           com.sun.jdmk/jmxtools
                                           com.sun.jmx/jmxri]]])
;(deps '[[log4j "1.2.16"]])
;(deps '[[log4j "1.2.15"]])

(deps '[[clj-logging-config "1.9.10"]]) 

; uit http://gphil.net/posts/2012-09-04-logging-in-clojure.html:
; "Finally, I had to explicitly add the log4j adapter for SLF4J in order to get everything to link up."
(deps '[[org.slf4j/slf4j-log4j12 "1.6.6"]])
; [com.revelytix.logbacks/slf4j-log4j12 "1.0.0"] ; deze uit clojars.

(require '[clojure.tools.logging :as log])
(require '[clj-logging-config.log4j :refer :all])  

(defn divide [x y]
  (log/info "dividing" x "by" y)
  (try
    (log/spyf "result: %s" (/ x y)) ; yields the result
    (catch Exception ex
      (log/error ex "There was an error in calculation"))))

(divide 1 2)

(divide 2 0)

(log/info "dividing" 1 "by" 2)

(log/error "Error")

(log/warn "Warning")


