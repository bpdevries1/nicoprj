#!/bin/bash lein-exec

; walk (complete) directory structure, find files bigger than treshold, put in sqlite DB.
; goal: further analysis, de-duplicate where possible.
; @todo later: also do on laptops, to find more duplicates.
; duplicates are not wrong per se, could be backups.
; also files on laptop might be gone any time...

(load-file "/home/nico/nicoprj/clojure/lib/def-libs.clj") 

(deps '[[org.clojure/core.async "0.1.278.0-76b25b-alpha"]])
(require '[clojure.core.async :as async :refer [>! <! >!! <!!]])

; removed from :refer -> chan sliding-buffer go close! go-loop timeout

(defn database-consumer
  "Accept messages and persist them to a database."
  []
  (let [in (async/chan (async/sliding-buffer 64))]
    (async/go-loop [data (<! in)]
             (when data
               (println (format "database-consumer received data %s" data))
               (recur (<! in))))
    in))

; loop/recur a bit different
(defn sse-consumer
  "Accept messages and pass them to web browsers via SSE."
  [finish-chan]
  (let [in (async/chan (async/sliding-buffer 64))]
    (async/go-loop []
             (if-let [data (<! in)]
               (do (println (format "sse-consumer received data %s" data))
                   (<! (async/timeout 1000))
                   ; (>! finish-chan :onedone)
                   (recur))
               (do (println "data is nil, reading is done.")
                   (>! finish-chan :done))))
    in))

(defn messages
  "Fetch messages from Twitter."
  []
  (range 4))

; this one doesn't work in a script: script exits before this task even starts.
; so either do the producing in the main thread or have some way to wait for everything to finish.
; could be that with producer2/consumer combination, the script exits before all consumers are done.
; this is indeed what happens.
(defn producer
  "Produce messages and deliver them to consumers."
  [& channels]
  (async/go
   (doseq [msg (messages)
           out  channels]
     (<! (async/timeout 100))
     (>! out msg))
   (doseq [out channels]
     (async/close! out))))

(defn main []
  (println "Started")
  (let [finish-chan (async/chan 1)]
    (producer (database-consumer) (sse-consumer finish-chan))
    (println (str "Result of reading finish-chan: " (<!! finish-chan))))
  (println "Finished"))  

(main)

