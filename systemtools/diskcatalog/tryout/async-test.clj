#!/bin/bash lein-exec

; async-test.clj - test clojure.core.async for use in script files.

; walk (complete) directory structure, find files bigger than treshold, put in sqlite DB.
; goal: further analysis, de-duplicate where possible.
; @todo later: also do on laptops, to find more duplicates.
; duplicates are not wrong per se, could be backups.
; also files on laptop might be gone any time...

; (load-file "/home/nico/nicoprj/clojure/lib/def-libs.clj") 

; (load-file "c:/nico/nicoprj/clojure/lib/def-libs.clj") 
; (load-file "/nico/nicoprj/clojure/lib/def-libs.clj")
(load-file "../../clojure/lib/def-libs.clj")

; diverse opties om load-file zowel op linux als windows werkend te krijgen:
; cygwin symlinks en sowieso cygwin paden werken niet.
; dus linux pad werkend onder cygwin lijkt lastig.
; dan ofwel 2 losse scripts, niet compatible, of heel klein wrapper script, evt soort lein-exec-win.
; of onder linux werkend maken met /c/nico/nicoprj door de goede symlink te maken, kan wel.
; of mss een ENV-var gebruiken?

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

(defn sse-consumer
  "Accept messages and pass them to web browsers via SSE."
  [finish-chan]
  (let [in (async/chan (async/sliding-buffer 64))]
    (async/go-loop [data (<! in)]
             (if data
               (do (println (format "sse-consumer received data %s" data))
                   (<! (async/timeout 1000))
                   ; (>! finish-chan :onedone)
                   (recur (<! in)))
               (do (println "data is nil, reading is done.")
                   (>! finish-chan :done))))
    in))

; loop/recur a bit different
(defn sse-consumer2
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

(defn producer2
  "Produce messages and deliver them to consumers."
  [& channels]
  (doseq [msg (messages)
          out  channels]
     (<!! (async/timeout 100))
     (>!! out msg))
  ; close channels so consumers will notice with getting a nil.
  (doseq [out channels]
    (async/close! out)))

(defn main []
  (println "Started")
  (let [finish-chan (async/chan 1)]
    (producer (database-consumer) (sse-consumer2 finish-chan))
    (println (str "Result of reading finish-chan: " (<!! finish-chan))))
  (println "Finished"))  

(main)

