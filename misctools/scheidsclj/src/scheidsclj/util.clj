; util: small utility functions for scheidsclj
(ns scheidsclj.util
  (:use scheidsclj.lib))

; 13-3-2011 and now in one function/call
(def new-sol-nr (make-counter 0))

; 13-3-2011 don't use this one, not sure if other clj files also need to be stated.
(defn reload []
  (load-file "src/scheidsclj/core.clj"))  

