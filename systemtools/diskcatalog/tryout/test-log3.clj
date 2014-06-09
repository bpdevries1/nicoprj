#!/bin/bash lein-exec

(use '[leiningen.exec :only  (deps)])

(deps '[[org.clojure/tools.logging "0.3.0"]])
(deps '[[org.slf4j/slf4j-log4j12 "1.7.5"]])
(require '[clojure.tools.logging :as log])

(defn divide [x y]
  (log/info "dividing" x "by" y)
  (try
    (log/spyf "result: %s" (/ x y)) ; yields the result
    (catch Exception ex
      (log/error ex "There was an error in calculation"))))

(divide 1 2)

; (divide 2 0)

(log/error "Error")

(log/warn "Warning")


