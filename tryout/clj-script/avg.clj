#!/bin/bash lein-exec

(defn err-println "println for STDERR"
  [& args]
  (binding [*out* *err*]
    (apply println args)))

(defn parse-int "Parse string as an integer. Abort if invalid."
  [n]
  (try (Integer/parseInt n)
    (catch NumberFormatException e
      (err-println (str \' n \')
                   "is not a valid integer")
      (System/exit 1))))

(defn avg "Given a sequence of numbers return their average."
  [nseq]
  (double (/ (apply + nseq) (count nseq))))

(if (>= (count *command-line-args*) 3)
  (println (second *command-line-args*)
           (avg (map parse-int (drop 2 *command-line-args*))))
  (do (err-println "Usage:" (first *command-line-args*)
                   "name score [score2 ..]")
    (System/exit 1)))

