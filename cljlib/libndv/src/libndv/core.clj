(ns libndv.core
  (:require [clj-time.core :as t]
            [clj-time.coerce :as tc]
            [clj-time.format :as tf]
            [potemkin.macros :as pm]
            [hiccup.page :refer [html5 include-js include-css]]
            [hiccup.form :refer [form-to text-field submit-button text-area
                                 drop-down hidden-field]]
            [ring.util.response :as response]))

;; TODO cleanup require list above, maybe use refactor command.

;; TODO not sure yet what to call a helpers file to put these functions in.
;; options: helpers_functional, helpers_map
(defn updates-in
  "'Updates' multiple values in a non-nested associative structure, where k is a
  key and f is a function that will take the old value
  and return the new value, and returns a new structure.
  allows for more than 1 keys and functions to be given.
  ks can be a single keyword or a vector of keywords.
  pairs of ks,f can be repeated (in args).
  If a key is not present in m, it will not be present in the result. If the value
  belonging to key is nil, there will be a value for key in the result."
  ([m ks f]
     (cond 
      (keyword? ks)
      (if (contains? m ks)
        (update-in m [ks] f) ; simpelste versie, naar update-in
        m)                   ; if m does not contain key, don't add it in the result.
      (empty? ks) m ; first need to check for :keyword, empty? fails on a :keyword
      ;; else should be a vector with at least 1 element.
      :else (updates-in (updates-in m (first ks) f) ; buitenste call terug naar deze of empty; binnenste naar versie waarbij ks een keyword is.
                        (rest ks)
                        f)))
  ([m ks f & args] ; >3 arguments, so more than one ks/f pair.
     (apply updates-in (updates-in m ks f) args))) ; buitenste call terug naar deze of versie met 3 params; binnenste call sowieso naar versie met 3 params.

(defn partial->
  "sort-of reverse partial: the returned function only needs the first param of the original function, rest of params have been filled in."
  [f & args]
  (fn [x]
    (apply f x args)))

(defn updates-in-fn [& args]
  (apply partial-> updates-in args))

(defn map-flatten
  "Flatten a map by moving all submaps to the top-level.
  If a value is a sequence, take the first element and flatten further.
  If a key occurs multiple times in a hierarchy, result is undefined."
  [m]
  (reduce-kv (fn [m1 k v]
               (cond (map? v) (merge m1 (map-flatten v))
                     (list? v) (merge m1 (map-flatten (first v)))
                     (vector? v) (merge m1 (map-flatten (first v)))
                     :else (assoc m1 k v))) {} m))



