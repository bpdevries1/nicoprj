(ns clojure-web-app.endpoint.example
  (:require [compojure.core :refer :all]
            [clojure.java.io :as io]))

(defn example-endpoint [config]
  (routes
   (GET "/" [] "Hello World and Nico again")))


