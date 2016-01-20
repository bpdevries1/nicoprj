(ns usetestje.core
  (:gen-class)
  (:require
   [libtestje.core :as t]
   ))

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (println "Hello, World!")
  (println (str "The answer = ") (t/give-answer)))

