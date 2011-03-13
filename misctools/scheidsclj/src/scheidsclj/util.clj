; util: small utility functions for scheidsclj
(ns scheidsclj.util
  (:use scheidsclj.lib))

; voor new-sol-nr wel 2 functions nodig: 1 die de counter-functie maakt, en 1 die 'em steeds aanroept.
; this should be possible with one function? with a closure?
;(def sol-nr-counter (make-counter 0))
;
;(defn new-sol-nr []
;  (sol-nr-counter))

; 13-3-2011 and now in one function/call
(def new-sol-nr (make-counter 0))

; 13-3-2011 don't use this one, not sure if other clj files also need to be stated.
(defn reload []
  (load-file "src/scheidsclj/core.clj"))  

