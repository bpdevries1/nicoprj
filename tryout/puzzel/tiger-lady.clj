(ns tigerlady)  

(defn make-combinations [lst]
  (if (empty? lst)
    (list (list))
    (let [lst-sub (make-combinations (rest lst))]
      (reduce concat (list) 
        (map (fn [el0] 
          (map #(concat (list el0) %) lst-sub)) (first lst))))))

(defn join [sep lst]
  "join a list with sep, make a string, equal to tcl join function
   in spirit of LISP put the separator first"
  (apply str (interpose sep lst)))

(defn main []
  (def lst '((hij-wil lady tiger)
             (zij-wil lady tiger)
             (hij-wil2 lady princess)
             (zij-wijst lady tiger)
             (hij-kiest same other)))
  (def lst-out (make-combinations (map (fn [el] (rest el)) lst)))

  (spit "tiger-lady.tsv" (str (join "\t" (map first lst)) "\n" (join "\n" (map #(join "\t" %) lst-out))))
)

(main)
