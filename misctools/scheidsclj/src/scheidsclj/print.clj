; print - printen naar het scherm (file?) van oplossingen
(ns scheidsclj.print)

; @todo moet deze naar stderr en moet ik een flush doen?
(defn puts-dot []
  (println ".") ; bij print wordt de . niet getoond, ook niet met flush.
  (flush))

(defn scheids-afko [scheids-naam]
   (apply str (map first (re-seq #"[^\s]+" scheids-naam)))) 

(defn kan-scheidsen [ar-inp-wedstrijden wedstrijd-id]
  (map #(scheids-afko (:scheids-naam %1)) 
    (:lst-kan-fluiten (ar-inp-wedstrijden wedstrijd-id))))

(defn opl-scheids-to-string [opl-scheids ar-inp-wedstrijden]
  (str (:wedstrijd-naam opl-scheids) " (zd=" (:zelfde-dag opl-scheids) ") "
       (:scheids-naam opl-scheids) " (" (scheids-afko (:scheids-naam opl-scheids)) 
       ") (zf=" (:zeurfactor opl-scheids) "/" (:waarde opl-scheids) ") ("
       (apply str (interpose ", " (kan-scheidsen ar-inp-wedstrijden (:wedstrijd-id opl-scheids)))) ")" ))

; nog een poging tot een macro
; alleen hier geen macro nodig
(defmacro printlnf-macro
  "Combi van println en format"
  [fmt & args]
  `(println (format ~fmt ~@args)))

(defn printlnf
  "Combi van println en format"
  [fmt & args]
  (println (apply format fmt args)))

;doseq is als foreach
; (doseq [i [1 2 3]] (println i))
; doall zou moeten werken om lazy te forcen, maar met str werkt dit niet zo
; sort werkt wel, ook wel logisch: om te sorten, moet je alle waarden hebben.
;@todo deze invullen.
; @todo kijken of format of str functie hier beter werkt.
; @param sol oplossing
; @param kan-naar-beter: functie die oplossing als input heeft, en true/false als output.
(defn print-solution [sol ar-inp-wedstrijden kan-naar-betere]
  (printlnf "Oplossing %d (parent: %d)" (:solnr sol) (:solnr-parent sol))
  (printlnf "Fitness: %f" (:fitness sol))
  (printlnf "Maximum aantal wedstrijden voor een scheidsrechter op een dag: %d" (:prod-wedstrijden-persoon-dag sol))
  (printlnf "Som van zeurfactoren: %f" (:som-zeurfactoren sol))
  (println "Lijst van zeurfactoren:" (sort (:lst-zeurfactoren sol)))
  (println "Aantal wedstrijden per scheidsrechter: " (sort (:lst-aantallen sol)))
  (printlnf "Maximum aantal wedstrijden voor een scheidsrechter: %d" (:max-scheids sol))
  (printlnf "Aantal verschillende scheidsrechters: %d" (:n-versch-scheids sol))
  (printlnf "Aantal wedstrijden: %d" (count (:vec-opl-scheids sol)))
  (println "Wedstrijden:")
  (doseq [sol-scheids (:vec-opl-scheids sol)] 
    (println (opl-scheids-to-string sol-scheids ar-inp-wedstrijden)))
  (println "--------------\nInfo per scheids:")
  ; * 1.0 nodig om integer naar float om te zetten, anders problemen bij format.
  (doseq [el (:lst-opl-persoon-info sol)]
    (printlnf "#%d zf=%6.1f : %s" (:nfluit el) (* 1.0 (:zeurfactor el)) (:scheids-naam el))) 
  (if (kan-naar-betere sol)
    (println "Vanuit deze oplossing is een BETERE te vinden met 1 change...")
    (println "Vanuit deze oplossing is GEEN betere te vinden met 1 change..."))
  (println "\n==========\n"))

(defn print-best-solution [proposition ar-inp-wedstrijden kan-naar-betere]
  (printlnf "Beste oplossing tot nu toe (iteratie %d):" (:iteration @proposition))
  (print-solution (first (:lst-solutions @proposition)) ar-inp-wedstrijden kan-naar-betere))

; @note wil eigenlijk alleen de beste oplossing zien.
(defn print-solutions [lst-solutions ar-inp-wedstrijden kan-naar-betere]
;  (doseq [sol lst-solutions]
;    (print-solution sol ar-inp-wedstrijden))
  (print-best-solution lst-solutions ar-inp-wedstrijden kan-naar-betere))
  
