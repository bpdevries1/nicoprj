; util: kleine utility functions voor scheidsclj, leiden anders af van de main functionaliteit
(ns scheidsclj.util
  (:use scheidsclj.lib))

; voor new-sol-nr wel 2 functions nodig: 1 die de counter-functie maakt, en 1 die 'em steeds aanroept.
(def sol-nr-counter (make-counter 0))

(defn new-sol-nr []
  (sol-nr-counter))

(defn reload []
  (load-file "src/scheidsclj/core.clj"))  

