(ns clj-instaparse-vugen.core
  (:gen-class)
  (:require [instaparse.core :as insta]
            [clojure.java.io :as io]))

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (println "Hello, World!"))

(def as-and-bs
  (insta/parser
   "S = AB*
     AB = A B
     A = 'a'+
     B = 'b'+"))

;; read syntax from file.
(def ini-parser-old
  (insta/parser (clojure.java.io/resource "ini.ebnf"))
  ;;(insta/parser "ini.ebnf")
  )

;; deze is ok:
;;(insta/parser "file:/home/nico/nicoprj/tryout/clj-instaparse-vugen/resources/ini.ebnf")

(def ini-res (clojure.java.io/resource "ini.ebnf"))

(def ini-parser (insta/parser (slurp ini-res)))

(def usr-text (slurp (io/resource "RRS_Users.usr")))

(def usr (ini-parser usr-text))

(def mini-text (slurp (io/resource "mini.usr")))
(def mini (ini-parser mini-text))


