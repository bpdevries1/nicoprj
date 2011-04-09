; break - debugging break macro implementation from Joy of Clojure
; with leiningen, need to do lein repl, not lein run, for this to work.
; doesn't seem to work at all in lein-repl:
; java.lang.RuntimeException: Can't embed object in code, maybe print-dup not defined: clojure.lang.Atom@14177f3 (NO_SOURCE_FILE:1)

(ns scheidsclj.break)

(defn readr [prompt exit-code]
  (let [input (clojure.main/repl-read prompt exit-code)]
    (if (= input ::tl)
      exit-code
      input)))

(defmacro local-context []
  (let [symbols (keys &env)]
     (zipmap (map (fn [sym] `(quote ~sym)) symbols) symbols)))

(defn contextual-eval [ctx expr]
  (eval
   `(let [~@(mapcat (fn [[k v]] [k `'~v]) ctx)]
      ~expr)))

(defmacro break []
  `(clojure.main/repl
    :prompt #(print "debug=> ")
    :read readr
    :eval (partial contextual-eval (local-context))))

