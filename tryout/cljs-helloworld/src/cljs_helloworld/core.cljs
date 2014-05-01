(ns cljs-helloworld.core)
 
(defn -main [& args]
  (println (apply str (map [\space "world" "hello"] [2 0 1]))))
 
(set! *main-cli-fn* -main)

