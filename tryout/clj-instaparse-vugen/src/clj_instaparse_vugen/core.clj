(ns clj-instaparse-vugen.core
  (:gen-class)
  (:require [instaparse.core :as insta]
            [clojure.java.io :as io]))

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (println "Hello, World!"))

(def ini-parser (-> "ini.ebnf" io/resource slurp insta/parser))

(defn ini-parse
  "Parse a string using ini-parser and transform"
  [s]
  (->> s ini-parser 
       (insta/transform {:Value str :Key str})))

(def usr-text (slurp (io/resource "RRS_Users.usr")))
(def usr (ini-parse usr-text))

(def mini-text (slurp (io/resource "mini.usr")))
(def mini (ini-parse-transform mini-text))

(def c-parser (-> "clang.ebnf" io/resource slurp insta/parser))

(def vuser-end-text (slurp (io/resource "vuser_end.c")))

;; total true -> embed failure node in tree.
(def vuser-end (c-parser vuser-end-text :total true :unhide :all))
#_(def vuser-end (insta/parses c-parser vuser-end-text :total true :unhide :all))


