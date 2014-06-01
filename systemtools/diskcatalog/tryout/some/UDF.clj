(ns some.UDF
  (:gen-class
   :extends org.sqlite.Function
   ; xFunc definieren
   
   ; result gebruiken (en later ook param-dingen)
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

(defn -xFunc [this]
  ;(println "#args: " (.argsSuper this))
  ;(println "type of arg0: " (.value_typeSuper this 0))
  ;(println "type of arg1: " (.value_typeSuper this 1))
  (if (and (= 2 (.argsSuper this))
           (= 3 (.value_typeSuper this 0))
           (= 3 (.value_typeSuper this 1)))
    ;(.resultSuper this "params ok")
    (.resultSuper this (sqlregexp (.value_textSuper this 0) (.value_textSuper this 1)))
    (.resultSuper this "syntax: sqlregexp('<RE>', '<String>')")))
    ;(.errorSuper this "syntax: sqlregexp('<RE>', '<String>')")))

