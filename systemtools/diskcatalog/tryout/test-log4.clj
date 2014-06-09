#!/bin/bash lein-exec

(use '[leiningen.exec :only  (deps)])

(deps '[[org.clojure/tools.logging "0.3.0"]])
(deps '[[org.slf4j/slf4j-log4j12 "1.7.5"]])
(deps '[[clj-logging-config "1.9.10"]]) 
(deps '[[me.raynes/fs "1.4.5"]])
(deps '[[clj-time "0.6.0"]])

(require '[clojure.tools.logging :as log])
; (require '[clj-logging-config.log4j :refer :all])
(require '[clj-logging-config.log4j :as logcfg])
(require '[me.raynes.fs :as fs])

(require '[clj-time.format :as tf])
(require '[clj-time.core :as t])

; (logcfg/set-logger! :pattern "%d - %m%n")
; (logcfg/set-logger! :level :debug :pattern "[%d] [%-5p] %m%n")

;(logcfg/set-logger! :level :debug :pattern "[%-5p] %m%n")
;(logcfg/set-logger! :level :debug :pattern "[%d] [%-5p] %m%n" :out "test-log4.log")

;(logcfg/set-loggers! 
;  "console" {:level :debug :pattern "[%-5p] %m%n"}
;  "logfile" {:level :debug :pattern "[%d] [%-5p] %m%n" :out "test-log4.log"})

;(logcfg/set-loggers!
;
;   "com.malcolmsparks.bar" 
;    {:level :debug}
;    
;    "com.malcolmsparks.foo" 
;    {:level :info :pattern "%m" :out "test-log4.log"})

; (logcfg/set-config-logging-level! :debug)

(defn logfile-name
  "Determine logfile based on script file name"
  [script-name]
  (let [dt (tf/unparse (tf/formatter "yyyy-MM-dd--hh-mm-ss") (t/now))]
    (str (fs/file (fs/parent script-name) (str (fs/name script-name) "-" dt ".log")))))

;(def my-format (tf/formatter "MMM d, yyyy 'at' hh:mm"))
;(tf/unparse my-format (t/now))
;; -> "Apr 6, 2013 at 04:54"
  
(logcfg/set-loggers! 
 (str *ns*) {:name "console" :level :debug :pattern "[%-5p] %m%n"}
 (str *ns*) {:name "file" :level :debug :pattern "[%d] [%-5p] %m%n" :out (logfile-name (first *command-line-args*))})

;(logcfg/set-logger! :level :warn)

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

(log/info (str "cmdline args: " *command-line-args*))

;(clojure.pprint/pprint (logcfg/get-logging-config))

