; lib: dingen die later breder gebruikt kunnen worden dan scheidsclj, vgl tcl lib.
(ns scheidsclj.lib)

; deze van Stuart Halloway op http://www.nofluffjuststuff.com/blog/stuart_halloway/2009/08/rifle_oriented_programming_with_clojure
; deze code mogelijk ook te gebruiken voor updaten van beste-oplossing.
(defn make-counter [init-val] 
  (let [c (atom init-val)] #(swap! c inc)))

(defn random-list [lst]
;(nth lst (rand-int (count lst))))
  (rand-nth lst))

; uit http://www.learningclojure.com/2010/03/conditioning-repl.html
(defn get-current-directory []
  (. (java.io.File. ".") getCanonicalPath))

