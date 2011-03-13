; print - printen naar het scherm (file?) van oplossingen
(ns scheidsclj.print)

; @todo moet deze naar stderr en moet ik een flush doen?
(defn puts-dot []
  (println ".") ; bij print wordt de . niet getoond, ook niet met flush.
  (flush))

(defn referee-afko [referee-naam]
   (apply str (map first (re-seq #"[^\s]+" referee-naam)))) 

(defn kan-refereeen [ar-inp-games game-id]
  (map #(referee-afko (:referee-naam %1)) 
    (:lst-kan-fluiten (ar-inp-games game-id))))

; @todo 6-3-2011 NdV dit lijkt wel een plek voor destucturing bind van opl-referee.
(defn opl-referee-to-string [opl-referee ar-inp-games]
  (str (:game-naam opl-referee) " (zd=" (:zelfde-dag opl-referee) ") "
       (:referee-naam opl-referee) " (" (referee-afko (:referee-naam opl-referee)) 
       ") (zf=" (:zeurfactor opl-referee) "/" (:waarde opl-referee) ") ("
       (apply str (interpose ", " (kan-refereeen ar-inp-games (:game-id opl-referee)))) ")" ))

(defn printlnf
  "Combination of println and format"
  [fmt & args]
  (println (apply format fmt args)))

; doall zou moeten werken om lazy te forcen, maar met str werkt dit niet zo
; sort werkt wel, ook wel logisch: om te sorten, moet je alle waarden hebben.
; @param sol oplossing
; @param kan-naar-beter: functie die oplossing als input heeft, en true/false als output.
(defn print-solution [sol ar-inp-games kan-naar-betere]
  (printlnf "Solution %d (parent: %d)" (:solnr sol) (:solnr-parent sol))
  (printlnf "Fitness: %f" (:fitness sol))
  (printlnf "Maximum #games for a referee on one day: %d" (:prod-games-persoon-dag sol))
  (printlnf "Sum of whine factors: %f" (:som-zeurfactoren sol))
  (println "List of whine factors:" (sort (:lst-zeurfactoren sol)))
  (println "#games per referee: " (sort (:lst-aantallen sol)))
  (printlnf "Maximum #games for a referee: %d" (:max-referee sol))
  (printlnf "#different referees: %d" (:n-versch-referee sol))
  (printlnf "#games: %d" (count (:vec-opl-referee sol)))
  (println "Games:")
  (doseq [sol-referee (:vec-opl-referee sol)] 
    (println (opl-referee-to-string sol-referee ar-inp-games)))
  (println "--------------\nReferees:")
  ; * 1.0 needed to cast integer to float, otherwise problems with format.
  (doseq [el (:lst-opl-persoon-info sol)]
    (printlnf "#%d zf=%6.1f : %s" (:nfluit el) (* 1.0 (:zeurfactor el)) (:referee-naam el))) 
  (if (kan-naar-betere sol)
    (println "from this solution a BETTER one can be found with 1 change...")
    (println "from this solution a better one CANNOT be found with 1 change..."))
  (println "\n==========\n"))

(defn print-best-solution [proposition ar-inp-games kan-naar-betere]
  (printlnf "Best solution so far (iteration %d):" (:iteration @proposition))
  (print-solution (first (:lst-solutions @proposition)) ar-inp-games kan-naar-betere))

; @note wil eigenlijk alleen de beste oplossing zien.
(defn print-solutions [lst-solutions ar-inp-games kan-naar-betere]
;  (doseq [sol lst-solutions]
;    (print-solution sol ar-inp-games))
  (print-best-solution lst-solutions ar-inp-games kan-naar-betere))
  
