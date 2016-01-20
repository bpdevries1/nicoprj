(ns libndv.debug)

;; TODO poor man's debugger, replace with real library
;; In Cider some options, for now ok.
(defn logline
  ([e] (logline "" e))
  ([s e]
     (println s e)
     e))

