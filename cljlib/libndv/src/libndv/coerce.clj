(ns libndv.coerce)

(defn to-int
  "Convert string to integer. Empty string will return nil"
  [s]
  (if (= java.lang.String (type s))
    (if (#{""} s)
      nil
      (Integer/parseInt s))
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

