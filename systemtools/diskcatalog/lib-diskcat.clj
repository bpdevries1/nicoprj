; lib-diskcat.clj - library with function for diskcatalog clojure scripts.

; c:\bieb\ICT-books\(eBook - comp) Introduction To Evolutionary Computing - A.eiben,j.smith (2003).djvu
; => /media/laptop/bieb/ICT-books/(eBook - comp) Introduction To Evolutionary Computing - A.eiben,j.smith (2003).djvu
(defn to-linux-path 
  "Convert laptop/windows path like c:\\bieb to /media/laptop/bieb"
  [path]
  (if-let [[_ part] (re-find #"^c:.(.*)$" path)] 
    (str "/media/laptop/" (clojure.string/replace part "\\" "/"))
    path))


