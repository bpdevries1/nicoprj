; in REPL:
; (require '(clojure-csv [core :as cdc]))
; (require '(clojure.contrib [pprint :as pp]))

; (:gen-class) niet nodig of helpt niet
(ns preprocess.core
  (:require [clojure-csv.core :as cdc]))

(defn csv-sanitize [csv]
  "Sanitize a csv sequence of sequences by removing all sublists with not same number of items as the first subsequence"
  (let [c (count (first csv))]
    (filter #(= (count %1) c) csv)))

; kan dit ook in Tcl?
(defn csv-transpose [csv]
  "Transpose a sequence of sequences"
  (apply map vector csv))

(defn csv-remove-columns [csv-t re]
  (filter #(not (re-find re (first %))) csv-t))

(defn csv-get-columns [csv-t re]
  (filter #(re-find re (first %)) csv-t))

(defn str-to-float [str]
  (if (re-find #"^[0-9\+\-\.e]+$" str)
    (Float/parseFloat str)
    0.0))

(defn sum-strings [& args]
  "args are strings; sum all elements that are convertible to floats and convert back to string"
  (Float/toString (apply + (map str-to-float args))))

(defn csv-sum-columns [csv-t header-name]
  "Sum the values in the same row of each colunn and return a csv-t with one column as a vector.
   Don't sum the first row, as it is a header row."
   (->> csv-t (map rest) (apply map sum-strings) (apply vector header-name) (vector)))

(defn preprocess [infilename outfilename]
  (let [csv-t (-> infilename slurp cdc/parse-csv csv-sanitize csv-transpose)
        csv-orig-t (csv-remove-columns csv-t #"(Logical Disk)|(Network Interface)")
        csv-net-t (-> csv-t (csv-get-columns #"Network Interface") (csv-sum-columns "Network Bytes Total/sec"))]
    (->> (concat csv-orig-t csv-net-t) csv-transpose cdc/write-csv (spit outfilename))))

(defn main [args]
  (let [[infilename outfilename] args]
    (preprocess infilename outfilename)))
  
(main *command-line-args*)


