(ns libndv.coerce)

;; 28-5-2015 postgres needs real int's in parameters, so convert here.
(defn to-int [s]
  (if (= java.lang.String (type s))
    (Integer/parseInt s)
    s))

;; to-key: like to-int, but convert 0 (zero) to nil, so postgres does not give f.key violation.
(defn to-key [s]
  (if (#{"" "0"} s)
    nil
    (to-int s)))

(defn to-float [s]
  (if (= java.lang.String (type s))
    (Float/parseFloat s)
    s))

