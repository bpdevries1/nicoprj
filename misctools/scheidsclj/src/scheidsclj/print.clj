; print - print solutions to the screen.
(ns scheidsclj.print)

(defn puts-dot []
  (println ".") ; with print de . (dot) won't be shown, not even with flush
  (flush))

(defn referee-initials [referee-name]
   (apply str (map first (re-seq #"[^\s]+" referee-name)))) 

(defn can-referee [ar-inp-games game-id]
  (map #(referee-initials (:referee-name %1)) 
    (:lst-can-referee (ar-inp-games game-id))))

; @todo 6-3-2011 NdV dit lijkt wel een plek voor destucturing bind van sol-referee.
(defn sol-referee-to-string [sol-referee ar-inp-games]
  (str (:game-name sol-referee) " (sd=" (:same-day sol-referee) ") "
       (:referee-name sol-referee) " (" (referee-initials (:referee-name sol-referee)) 
       ") (wf=" (:whinefactor sol-referee) "/" (:value sol-referee) ") ("
       (apply str (interpose ", " (can-referee ar-inp-games (:game-id sol-referee)))) ")" ))

(defn printlnf
  "Combination of println and format"
  [fmt & args]
  (println (apply format fmt args)))

; doall zou moeten werken om lazy te forcen, maar met str werkt dit niet zo
; sort werkt wel, ook wel logisch: om te sorten, moet je alle waarden hebben.
; @param sol oplossing
; @param kan-naar-beter: functie die oplossing als input heeft, en true/false als output.
(defn print-solution [sol ar-inp-games can-find-better]
  (printlnf "Solution %d (parent: %d)" (:solnr sol) (:solnr-parent sol))
  (printlnf "Fitness: %f" (:fitness sol))
  (printlnf "Maximum #games for a referee on one day: %d" (:prod-games-person-day sol))
  (printlnf "Sum of whine factors: %f" (:sum-whinefactors sol))
  (println "List of whine factors:" (sort (:lst-whinefactors sol)))
  (println "#games per referee: " (sort (:lst-counts sol)))
  (printlnf "Maximum #games for a referee: %d" (:max-referee sol))
  (printlnf "#different referees: %d" (:n-diff-referee sol))
  (printlnf "#games: %d" (count (:vec-sol-referee sol)))
  (println "Games:")
  (doseq [sol-referee (:vec-sol-referee sol)] 
    (println (sol-referee-to-string sol-referee ar-inp-games)))
  (println "--------------\nReferees:")
  ; * 1.0 needed to cast integer to float, otherwise problems with format.
  (doseq [el (:lst-sol-person-info sol)]
    (printlnf "#%d zf=%6.1f : %s" (:nreferee el) (* 1.0 (:whinefactor el)) (:referee-name el))) 
  (if (can-find-better sol)
    (println "from this solution a BETTER one can be found with 1 change...")
    (println "from this solution a better one CANNOT be found with 1 change..."))
  (println "\n==========\n"))

(defn print-best-solution [proposition ar-inp-games can-find-better]
  (printlnf "Best solution so far (iteration %d):" (:iteration @proposition))
  (print-solution (first (:lst-solutions @proposition)) ar-inp-games can-find-better))

; @note wil eigenlijk alleen de beste oplossing zien.
(defn print-solutions [lst-solutions ar-inp-games can-find-better]
;  (doseq [sol lst-solutions]
;    (print-solution sol ar-inp-games))
  (print-best-solution lst-solutions ar-inp-games can-find-better))
  
