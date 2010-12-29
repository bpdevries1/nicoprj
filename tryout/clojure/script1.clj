;doelen:
; commandline args lezen en gebruiken
; bestand lezen en schrijven
; ofwel script uitvoeren

;later
;evol algo lib voor clojure, hiermee de teams te doen?

(println 42)

(println *command-line-args*)

(apply println *command-line-args*)

(println (slurp "script1.clj"))

(use '[clojure.contrib.duck-streams :only (spit)])
(spit "hello.out" "hello, world")

;blz 156 van practical clojure

(gen-class MyMain
  :main true)
(defn -main [& args] 
  (apply println args))

