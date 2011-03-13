; lib: things that can be used more generally than in refereeclj.
(ns scheidsclj.lib)

; this one from Stuart Halloway on http://www.nofluffjuststuff.com/blog/stuart_halloway/2009/08/rifle_oriented_programming_with_clojure
(defn make-counter [init-val] 
  (let [c (atom init-val)] #(swap! c inc)))

; from http://www.learningclojure.com/2010/03/conditioning-repl.html
(defn get-current-directory []
  (. (java.io.File. ".") getCanonicalPath))

