; some tryouts with macro's to print debug symbols and values.
; see also clojure-macros.txt

; macro println-symbol
; call: (println-symbol paths-file)
; replace with: (println "paths-file: " paths-file)
(defmacro println-symbol
  "Print a symbol name with its value"
  [sym]
  `(println (str '~sym ": " ~sym)))

; doseq op macro niveau of normale niveau? Denk macro niveau
; @todo add # to internal var?
(defmacro println-symbols
  "Print a sequence of symbol names with their values"
  [& symbols]
  (doseq [sym1 symbols]
    (println-symbol 'sym1)))    

; deze werkt (optie 3):
(defmacro println-symbols
  [& symbols]
  (cons 'do (map #(list 'println-symbol %) symbols))) 

; deze werkt ook, zonder list, maar met fn, wil ook andersom
(defmacro println-symbols
  [& symbols]
  `(do ~@(map (fn [s#] `(println-symbol ~s#)) symbols))) 

; voorkeurs versie nu, de kortste
(defmacro pr-syms
  [& symbols]
  `(do ~@(map #(list 'println-symbol %) symbols))) 

; deze iets langer, maar geen tussenliggende macro nodig:
; deze nu in 'productie' gebruikt, en werkt.
(defmacro pr-syms
  [& symbols]
  `(do ~@(map (fn [s] `(println '~s "=" ~s)) symbols))) 

; en deze op andere manier, met doseq nog in de macroexpanded versie.
; vraag of deze het meest idiomatic is.
; deze doet het niet in 'productie', paths-file niet gevonden in context. Mss net andere namespace, iets met let.
(defmacro pr-syms
  "Print a sequence of symbol names with their values"
  [& symbols]
  `(doseq [sym# '~symbols]
    (println sym# "=" (eval sym#))))  

