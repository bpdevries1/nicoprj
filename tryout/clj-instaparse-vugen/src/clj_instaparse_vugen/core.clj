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
(def mini (ini-parse mini-text))

#_(def c-parser (-> "clang.ebnf" io/resource slurp (insta/parser :auto-whitespace :standard)))

(def c-grammar (-> "clang.ebnf" io/resource slurp))
(def c-parser (insta/parser c-grammar :auto-whitespace :standard))

(def vuser-end-text (slurp (io/resource "vuser_end.c")))

(defn measured-parse
  "Measure time and number of parse trees"
  [parser text]
  (println "First tree:")
  (time (insta/parse parser text))
  (println "All trees:")
  (let [trees (time (insta/parses parser text :total true :unhide :all))]
    (println "Number of characters:" (count text))
    (println "Number of trees:" (count trees))
    trees))

(defn measured-parse-file
  "Measured parse of a file, see measured-parse"
  [parser filename]
  (println "Filename:" filename)
  (measured-parse parser (slurp (io/resource filename))))

(defn measured-single-parse-file
  "Like previous, but just one, is faster"
  [parser filename]
  (println "Filename:" filename)
  (time (insta/parse parser (slurp (io/resource filename)))))

(defn pprint-file
  "pretty print part of trees to filename"
  [trees ndx basename]
  (pprint (nth trees ndx) (io/writer (str "/tmp/"  basename "-" ndx ".txt"))))

(defn pprint-file-trees
  "Print all trees of parse to a separate file"
  [trees basename]
  (doseq [ndx (range (count trees))]
    (pprint-file trees ndx basename)))

;; total true -> embed failure node in tree.
(time (def vuser-end (c-parser vuser-end-text :total true :unhide :all)))
#_(time (def vuser-ends (insta/parses c-parser vuser-end-text :total true :unhide :all)))

(def vuser-ends (measured-parse c-parser vuser-end-text))

(def landing-text (slurp (io/resource "landing.c")))
(def revert-text (slurp (io/resource "revert.c")))
;; total true -> embed failure node in tree.
#_(def landing (c-parser landing-text :total true :unhide :all))

#_(def landing-2 (measured-parse-file c-parser "landing-2.c"))
#_(def landing-4 (measured-parse-file c-parser "landing-4.c"))
#_(def landing-19 (measured-parse-file c-parser "landing-19.c"))
#_(def landing-35 (measured-parse-file c-parser "landing-35.c"))
#_(def landing-75 (measured-parse-file c-parser "landing-75.c"))
#_(def landing-78 (measured-parse-file c-parser "landing-78.c"))
#_(def landing-86 (measured-parse-file c-parser "landing-86.c"))
#_(def landing-89 (measured-parse-file c-parser "landing-89.c"))
#_(def landing-95 (measured-parse-file c-parser "landing-95.c"))
#_(def landing-104 (measured-parse-file c-parser "landing-104.c"))
#_(def landing-106 (measured-parse-file c-parser "landing-106.c"))
;; [2016-12-31 23:10] deze lukt niet, maar eerste lijkt wel te lukken.
#_(def landing (measured-parse-file c-parser "landing.c"))
(def revert (measured-parse-file c-parser "revert.c"))
(def landing (measured-single-parse-file c-parser "landing.c"))

;; (clojure.pprint/pprint *map* (clojure.java.io/writer "foo.txt"))


