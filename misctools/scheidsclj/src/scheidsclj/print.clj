; print - print solutions to the screen.
(ns scheidsclj.print)

; test with *err*
; [2012-01-02 21:57:00] doesn't work in lein run, works in lein-repl.
(defn log-err [s]
  (binding [*out* *err*] ; binds *out* to the same as what *err* is bound to, i.e. stderr
  ;(binding [*err* *out*]
    (print s)
    (flush)))

(defn test-log-err []
  (println "Testing test-log-err")
  (log-err ".")
  (Thread/sleep 1000)
  (log-err ".")
  (Thread/sleep 1000)
  (log-err ".")
  (println)
  (flush)
  (println "Finished testing test-log-err"))

; Works in uberjar version, not within REPL!
; Thread/sleep is not needed, flush is needed!
(defn puts-dot []
  (print ".") ; with print the . (dot) won't be shown, not even with flush
  (flush))
  ;(Thread/sleep 1000)) ; even testen met vrij grote waarde. Zelfs deze werkt niet!

; @todo could have something to do with the REPL or leiningen.
(defn puts-dot-old []
  (println ".") ; with print the . (dot) won't be shown, not even with flush
  (flush))

(defn referee-initials [referee-name]
   (apply str (map first (re-seq #"[^\s]+" referee-name)))) 

(defn can-referee [ar-inp-games game-id]
  (map #(referee-initials (:referee-name %1)) 
    (:lst-can-referee (ar-inp-games game-id))))

; :as sol-referee not needed in destructuring
(defn sol-referee-to-string [{:keys [game-name same-day referee-name whinefactor value game-id]} 
                             ar-inp-games]
  (str game-name " (sd=" same-day ") "
       referee-name " (" (referee-initials referee-name) 
       ") (wf=" whinefactor "/" value ") ("
       (apply str (interpose ", " (can-referee ar-inp-games game-id))) ")" ))

(defn printlnf
  "Combination of println and format"
  [fmt & args]
  (println (apply format fmt args)))

; doall zou moeten werken om lazy te forcen, maar met str werkt dit niet zo
; sort werkt wel, ook wel logisch: om te sorten, moet je alle waarden hebben.
; @param sol oplossing
; @param can-find-better: functie die oplossing als input heeft, en true/false als output.
; @todo 1-1-2012: bij soseq ook destructuring te doen?
(defn print-solution [{:keys [solnr solnr-parent vec-sol-referee 
                              lst-sol-person-info fitness prod-games-person-day 
                              sum-whinefactors lst-whinefactors lst-counts 
                              max-referee n-diff-referee] :as sol}               ; :as sol needed for can-find-better                 
                      ar-inp-games can-find-better]
  (printlnf "Solution %d (parent: %d)" solnr solnr-parent)
  (println "Games:")
  (doseq [sol-referee vec-sol-referee] 
    (println (sol-referee-to-string sol-referee ar-inp-games)))
  (println "--------------\nReferees:")
  ; * 1.0 needed to cast integer to float, otherwise problems with format.
  (doseq [{:keys [nreferee whinefactor referee-name]} lst-sol-person-info] 
    (printlnf "#%d zf=%6.1f : %s" nreferee (* 1.0 whinefactor) referee-name)) 
  (println "--------------\nStatistics:")
  (printlnf "Fitness: %f" fitness)
  (printlnf "Maximum #games for a referee on one day: %d" prod-games-person-day)
  (printlnf "Sum of whine factors: %f" sum-whinefactors)
  (println "List of whine factors:" (sort lst-whinefactors))
  (println "#games per referee: " (sort lst-counts))
  (printlnf "Maximum #games for a referee: %d" max-referee)
  (printlnf "#different referees: %d" n-diff-referee)
  (printlnf "#games: %d" (count vec-sol-referee))
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
  
