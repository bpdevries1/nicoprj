(ns cljs-node2.core)

(def express (js/require "express")) ;; require express
(def app        (express))                    ;; create the app
(def fs           (js/require "fs"))            ;; require fs
(def *rs* nil)

;; localhost:3000
(.get app "/" (fn [req res]
                (.send res "Hello world!")))

;; localhost:3000/user/andrei
(.get app "/user/:name" (fn [req res]
                     (.send res (aget req "params" "name"))))

;; localhost:3000/read
;; be sure to specify a valid path to read from
(.get app "/read"
      (fn [req res]
        (set! *rs* (.createReadStream fs "testfile.txt"))
        (.pipe *rs* res)))

;; what port to bind the application on
(.listen app 3000)

(defn start [& _]
  (println "Server started on port 3000"))

;; must have a main function
(set! *main-cli-fn* start)

