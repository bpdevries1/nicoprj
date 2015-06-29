;; SqlRegExp.clj

;; Instructions for compiling (it's tricky):
;; 1. lein repl
;; 2. (load-file "../../clojure/lib/def-libs.clj")
;; 3. (compile 'SqlRegExp)

;; tried some other things, but failed. Possibly using lein complete/project will work as well.

;; putting this load-file does compile from a clean repl, but errors while executing.
;; (load-file "../../clojure/lib/def-libs.clj")

;; org.sqlite.Function is needed.
;; but including stuff below also causes strange errors when compiling:
;;(use '[leiningen.exec :only  (deps)])
;;(deps '[[org.clojure/java.jdbc "0.3.3"]
;;        [org.xerial/sqlite-jdbc "3.7.2"]]) ; 3.7.2 lijkt nog wel de nieuwste ([2014-05-03 22:39:14])
;;(require '[clojure.java.jdbc :as jdbc])
        
(ns SqlRegExp
  (:gen-class
   :extends org.sqlite.Function
   :exposes-methods {args argsSuper error errorSuper 
                    value_text value_textSuper value_type value_typeSuper 
                    result resultSuper}
   :main false))

(defn sqlregexp
  "Regular expression function to be used in SQLite. 
   If there is a match, and parens are used, the first match will be returned."
  [re str]
  (when-let [res (re-find (re-pattern re) str)]
    (cond (= (type res) java.lang.String) res
          (= (type res) clojure.lang.PersistentVector) (second res))))

; type 3 is string, type 1 is int, type 2 is float/bignumber.
; error function does work, but does not give sensible error to user, so put error in result, is more clear.
(defn -xFunc [this]
  (if (and (= 2 (.argsSuper this))
           (= 3 (.value_typeSuper this 0))
           (= 3 (.value_typeSuper this 1)))
    (.resultSuper this (sqlregexp (.value_textSuper this 0) (.value_textSuper this 1)))
    (.resultSuper this "syntax: sqlregexp('<RE>', '<String>')")))

