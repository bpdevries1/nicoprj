#!/bin/bash lein-exec

(use '[leiningen.exec :only  (deps)])
(deps '[[ring "1.0.1"]])

(defn handler
  [request]
  {:status 200
   :headers {}
   :body "Hello from Ring!"})

(use 'ring.adapter.jetty)
(run-jetty handler {:port 3000})


