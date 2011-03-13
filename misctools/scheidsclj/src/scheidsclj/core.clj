;( ; deze als haakjes niet kloppen.
(ns scheidsclj.core
  (:gen-class)
  
  ; (:require clojure.contrib.repl-utils) ; nodig voor ctrl-c handling

  (:use scheidsclj.db)
  (:use scheidsclj.geneticlib)
  (:use scheidsclj.lib)
  (:use scheidsclj.util)
  (:use scheidsclj.print))

; global vars, but only set/read-in once.
(declare *lst-inp-games* *lst-inp-personen* *ar-inp-games*) 
  
(defn select-referee [game referee]
  (merge (select-keys game [:game-id :game-naam :datum])
         (select-keys referee [:referee-id :referee-naam :zeurfactor :waarde :zelfde-dag])))
  
; @result game-hashmap, als element in vec-opl-referee
(defn choose-random-referee [game-id]
  (let [game (*ar-inp-games* game-id)
        referee (rand-nth (:lst-kan-fluiten game))]
    (select-referee game referee))) 

; @note hogere fitness is beter.
; prod_games_persoon_dag: 1..veel minder is beter, alles meer dan 1 is gewoon fout.
; wel bepalen hoe fout het is, zodat het beter kan worden, als bv 2 personen elk 2x op een dag moeten fluiten.
; max_referee: 1..10 minder is beter
; n_versch_referee: 1..20 meer is beter
; som_zeurfactoren: 0..10000 minder is beter
; door 1-maxwedstrperdag wordt dit deel 0 als het gewoon goed is, en negatief bij fouten.
; 19-9-2010 NdV max_referee toch niet zo belangrijk, zelfdedag telt minder dan andere dag, en in zf al rekening mee gehouden.
; 19-9-2010 NdV zelfde geldt eigenlijk ook voor aantal verschillende refereeen.
; 19-9-2010 NdV maar wel de lasten goed verdelen, dus max_zeurfactoren wel belangrijk.
; expr (1-$prod_games_persoon_dag) * 100000 + (10-$max_referee)*100 + $n_versch_referee - (0.0001 * $som_zeurfactoren)
(defn calc-fitness [prod-games-persoon-dag max-referee n-versch-referee som-zeurfactoren max-zeurfactoren]
  (- (* (- 1 prod-games-persoon-dag) 100000)
     max-zeurfactoren
     (* 0.0001 som-zeurfactoren)))

; bepaal per persoon welke games deze fluit in de gemaakte oplossing
; input lijst van personen (hashmap)
; result lijst van personen (hashmap) aangevuld met lijst van games per persoon
(defn det-persoon-games [lst-inp-personen vec-opl-referee]
  (map #(assoc %1 :lst-games (for [opl vec-opl-referee :when (= (:referee-id %1) (:referee-id opl))]
    opl)) lst-inp-personen))

; deze nog herschrijven met -> of ->>
; elke persoon heeft lijst van games, elke game is een hashmap. Maak per hashmap een nieuwe, zodat ze met merge-with opgeteld kunnen worden per persoon
(defn det-prod-games-persoon-dag [lst-persoon-games]
  (apply * 
    (map (fn [persoon] 
      (apply *
        (vals
          (apply merge-with + 
            (map #(hash-map (:datum %) 1) (:lst-games persoon)))))) lst-persoon-games)))
  
(defn det-lst-opl-persoon-info [lst-persoon-games]
  (map #(assoc % 
              :nfluit (count (:lst-games %))
              :zeurfactor (apply * (map :zeurfactor (:lst-games %)))) lst-persoon-games))

; bepaal sleutel waarden van de oplossing
; @result hashmap
(defn det-opl-values [lst-inp-personen vec-opl-referee]
  (let [lst-persoon-games (det-persoon-games lst-inp-personen vec-opl-referee)]
    (hash-map 
      :lst-zeurfactoren (map #(* (:zeurfactor %1)
                          (apply * (for [opl (:lst-games %1)] 
                             (/ (:zeurfactor opl) (:waarde opl))))) lst-persoon-games)
      :lst-aantallen (map #(count (:lst-games %1)) lst-persoon-games)
      :prod-games-persoon-dag (det-prod-games-persoon-dag lst-persoon-games)
      :lst-opl-persoon-info (det-lst-opl-persoon-info lst-persoon-games))))

(defn add-statistics [vec-opl-referee note solnr-parent]
  (let [opl-values (det-opl-values *lst-inp-personen* vec-opl-referee)
        n-versch-referee (count (for [n (:lst-aantallen opl-values) :when (> n 0)] 1))
        lst-zeurfactoren (:lst-zeurfactoren opl-values)] 
    (assoc opl-values
            :vec-opl-referee vec-opl-referee
            :note note
            :solnr (new-sol-nr)
            :solnr-parent solnr-parent
            :fitness (calc-fitness (:prod-games-persoon-dag opl-values) 
                                   (apply max (:lst-aantallen opl-values)) 
                                   n-versch-referee 
                                   (apply + lst-zeurfactoren) 
                                   (apply max lst-zeurfactoren))
            :max-referee (apply max (:lst-aantallen opl-values))
            :n-versch-referee n-versch-referee
            :som-zeurfactoren (apply + lst-zeurfactoren)
            :max-zeurfactoren (max lst-zeurfactoren))))

; beetje raar dat choose-random-referee met de game-id wordt aangeroepen, en niet met de game gegevens
; zelf. Zo gedaan omdat deze functie vanuit meerdere plekken wordt aangeroepen, en de gegevens niet overal bekend
; zijn. 
; @todo nog refactoren zodat het meer functioneel wordt, niet afhankelijk van global variables.
(defn make-solution [lst-input-games]
  (let [vec-opl-referee (vec (map #(choose-random-referee (:game-id %1)) lst-input-games))]
    (add-statistics vec-opl-referee "Initial solution" 0)))

(defn mutate-game [opl-referee]
  (choose-random-referee (:game-id opl-referee)))
        
; @note tail-recursive, sort-of continuation style passing?
(defn mutate-solution-rec [n vec-opl-referee solnr-parent]
  (if (zero? n) 
    (add-statistics vec-opl-referee "Mutated game(s)" solnr-parent)
    (recur (dec n) 
      (let [rnd (rand-int (count vec-opl-referee))]
        (assoc vec-opl-referee rnd (mutate-game (get vec-opl-referee rnd))))
      solnr-parent)))      
      
; @todo de rand-int 2 waarde halen uit de command-line params. Hier ook een goede lib voor?
; bepaal randomwaarde 1 of 2, en muteer oplossing zo vaak
(defn mutate-solution [sol]
  (mutate-solution-rec (inc (rand-int 2)) (:vec-opl-referee sol) (:solnr sol)))

; globals definieren met def, dan maar eenmalig een waarde toegekend (?)
; en krijgen pas een waarde bij uitvoeren, dus in andere functies niet bekend op compile time.
(defn init-globals []
  (def *lst-inp-games* (query-input-games))
  (def *lst-inp-personen* (det-lst-inp-personen)) 
  (def *ar-inp-games* 
    (zipmap (map :game-id *lst-inp-games*) *lst-inp-games*)))


; @result fitness of sol if game with index game-index is refereed by referee
(defn fitness-sol-game-change-referee [vec-opl-referee game-index referee]
      ;(let [rnd (rand-int (count vec-opl-referee))]
  (-> (assoc vec-opl-referee game-index 
         (select-referee (get vec-opl-referee game-index) referee))
      (add-statistics "" 0)
      (:fitness)))
      
; @result max fitness als bij oplossing sol de game met index game-index wordt aangepast.
; lst-kan-fluiten uit *ar-inp-games* halen, niet uit vec-opl-referee
; vraag of je deze info ook niet bij oplossing wilt zetten, is toch read-only/immutable.
(defn max-fitness-sol-game-change [vec-opl-referee game-index]
  (apply max (map #(fitness-sol-game-change-referee vec-opl-referee game-index %) 
    (:lst-kan-fluiten (*ar-inp-games* (:game-id (get vec-opl-referee game-index))))
    )))

; @todo deze implementeren, dan wel maak-oplossing functies nodig)
; @note beetje map-reduce achtig: per game die je aanpast een andere functie, is dan parallel uit te voeren.
(defn kan-naar-betere [sol]
  (> (apply max (map #(max-fitness-sol-game-change (:vec-opl-referee sol) %)
                     (range (count (:vec-opl-referee sol)))))
    (:fitness sol)))

; @todo alleen saven bij een minimale fitness.
(defn handle-best-solution [proposition]
  (print-best-solution proposition *ar-inp-games* kan-naar-betere)
  (let [sol (first (:lst-solutions @proposition))]
    (if (> (:fitness sol) -2000)
      (save-solution sol))))

; @note evol-iteration functioneel opzetten: je krijgt iteratie en lijst oplossingen binnen, en retourneert deze ook.
; opties 1) handle-best-solution een sol meegeven. 2) de swap! in deze functie, dan handle aanroepen
; 3) check niet in deze function, maar in aanroepende maak-voorstel, dan hier ook de puts-dot in.
; keuze is nu optie 3
(defn evol-iteration [{:keys [lst-solutions iteration]}]
  (let [new-iteration (inc iteration)
        old-fitness (:fitness (first lst-solutions))
        new-solutions (map mutate-solution lst-solutions)
        sorted-solutions (sort-by :fitness > (concat new-solutions lst-solutions))
        best-solutions (take (count lst-solutions) sorted-solutions)
        new-fitness (:fitness (first best-solutions))]
     {:lst-solutions best-solutions 
      :iteration new-iteration}))   

(defn make-proposition [sol-args]
  (println "Make proposition" sol-args)
  (init-globals)
  (let [proposition (atom {:lst-solutions (repeatedly (:pop sol-args) #(make-solution *lst-inp-games*))
               :iteration 1})
        fitness (atom (:fitness (first (:lst-solutions @proposition))))]
    (while (< (:fitness (first (:lst-solutions @proposition))) (:fitness sol-args))
      (swap! proposition evol-iteration)
      (if (zero? (mod (:iteration @proposition) 100))
        (puts-dot))
      (when (> (:fitness (first (:lst-solutions @proposition))) @fitness)
        (reset! fitness (:fitness (first (:lst-solutions @proposition))))
        (handle-best-solution proposition)))
    (printlnf "Fitness: %f (goal: %f)" @fitness (:fitness sol-args))))

(defn -main [& args]
  (open-global-db)
  (delete-oude-voorstel)

  (let [sol-args {:pop 10
                  :iter 0
                  :fitness 100000
                  :nmutations 2
                  :loglevel ""
                  :print "better"}]
    (make-proposition sol-args))                  
  (close-global-db))  

;) ; deze als haakjes niet kloppen.
