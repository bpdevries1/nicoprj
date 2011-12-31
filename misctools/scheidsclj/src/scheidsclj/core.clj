;( ; deze als haakjes niet kloppen.
(ns scheidsclj.core
  (:gen-class)
;  (:use scheidsclj.break)
  (:use scheidsclj.db)
  (:use scheidsclj.geneticlib)
  (:use scheidsclj.lib)
  (:use scheidsclj.util)
  (:use scheidsclj.print)
  (:use clargon.core)) ; was clojopts, but vague with not supplied optional arguments.

; global vars, but only set/read-in once.
(declare *lst-inp-games* *lst-inp-persons* *ar-inp-games*) 
  
(defn select-referee [game referee]
  (merge (select-keys game [:game-id :game-name :date])
         (select-keys referee [:referee-id :referee-name :whinefactor :value :same-day])))
  
; @result game-hashmap, als element in vec-sol-referee
(defn choose-random-referee [game-id]
  "@result game-hashmap, as element in vec-sol-referee"
  (let [game (*ar-inp-games* game-id)
        referee (rand-nth (:lst-can-referee game))]
    (select-referee game referee))) 

; @note hogere fitness is beter.
; prod_games_person_dag: 1..veel minder is beter, alles meer dan 1 is gewoon fout.
; wel bepalen hoe fout het is, zodat het beter kan worden, als bv 2 persons elk 2x op een dag moeten fluiten.
; max_referee: 1..10 minder is beter
; n_versch_referee: 1..20 meer is beter
; sum-whinefactors: 0..10000 minder is beter
; door 1-maxwedstrperdag wordt dit deel 0 als het gewoon goed is, en negatief bij fouten.
; 19-9-2010 NdV max_referee toch niet zo belangrijk, zelfdedag telt minder dan andere dag, en in zf al rekening mee gehouden.
; 19-9-2010 NdV zelfde geldt eigenlijk ook voor aantal verschillende refereeen.
; 19-9-2010 NdV maar wel de lasten goed verdelen, dus max_whinefactors wel belangrijk.
; expr (1-$prod_games_person_dag) * 100000 + (10-$max_referee)*100 + $n_versch_referee - (0.0001 * $sum-whinefactors)
; 31-12-2011 prod-games-person-day van 100.000 naar 1 miljoen gezet, bepaalde zf's staan ook op 100.000.
(defn calc-fitness [prod-games-person-day max-referee n-diff-referee sum-whinefactors max-whinefactors]
  (- (* (- 1 prod-games-person-day) 1000000)
     max-whinefactors
     (* 0.0001 sum-whinefactors)))

; bepaal per person welke games deze fluit in de gemaakte oplossing
; input lijst van persons (hashmap)
; result lijst van persons (hashmap) aangevuld met lijst van games per person.
; 31-12-2011 zeurfactor hier dus nog niet berekend voor combi van oud en nieuw:
;            oud staat er nog in, nieuw te bepalen uit lijst van wedstrijden.
(defn det-person-games [lst-inp-persons vec-sol-referee]
  (map #(assoc %1 :lst-games (for [sol vec-sol-referee :when (= (:referee-id %1) (:referee-id sol))]
    sol)) lst-inp-persons))

(defn det-prod-games-person-day [lst-person-games]
  "determine product of product of #games of this person/referee on each day"
  (letfn [(det-games-person-day [person]
    (->> (map #(hash-map (:date %) 1) (:lst-games person)) ; make list of hashmaps for each game, date is key.
         (apply merge-with +)                              ; add per day
         (vals)                                            ; remove keys, just a list of values, should be all 1's.
         (apply *)))]                                      ; multiply. Should be 1, not more than 1 game per day per person.
    (apply * (map det-games-person-day lst-person-games))))

; 31-12-2011 nu wel met meeneming van de oude info: product zf's en ook #games oud.
(defn det-lst-sol-person-info [lst-person-games]
  (map #(assoc % 
              :nreferee (+ (:nreferee %) (count (:lst-games %)))
              :whinefactor (* (:whinefactor %) (apply * (map :whinefactor (:lst-games %))))) lst-person-games))

; 31-12-2011 had hier nog niet de oude info meegenomen.
(defn det-lst-sol-person-info-old [lst-person-games]
  (map #(assoc % 
              :nreferee (count (:lst-games %))
              :whinefactor (apply * (map :whinefactor (:lst-games %)))) lst-person-games))

; 31-12-2011 nu ook voor aantal wedstrijden het orig/oude aantal meenemen, net als zeurfactoren.
(defn det-sol-values [lst-inp-persons vec-sol-referee]
  "determine key values of the solution. @result hashmap"
  (let [lst-person-games (det-person-games lst-inp-persons vec-sol-referee)]
    (hash-map 
      :lst-whinefactors (map #(* (:whinefactor %1)                                     ; vermenigvuldig whinefactor van oude
                          (apply * (for [sol (:lst-games %1)]                          ; met product van die van de nieuwe.
                             (/ (:whinefactor sol) (:value sol))))) lst-person-games)
      :lst-counts (map #(+ (:nreferee %1) (count (:lst-games %1))) lst-person-games)   ; hier nu wel bestaande meegenomen.
      :prod-games-person-day (det-prod-games-person-day lst-person-games)
      :lst-sol-person-info (det-lst-sol-person-info lst-person-games))))

(defn det-sol-values-old [lst-inp-persons vec-sol-referee]
  "determine key values of the solution. @result hashmap"
  (let [lst-person-games (det-person-games lst-inp-persons vec-sol-referee)]
    (hash-map 
      :lst-whinefactors (map #(* (:whinefactor %1)                                     ; vermenigvuldig whinefactor van oude
                          (apply * (for [sol (:lst-games %1)]                          ; met product van die van de nieuwe.
                             (/ (:whinefactor sol) (:value sol))))) lst-person-games)
      :lst-counts (map #(count (:lst-games %1)) lst-person-games)                      ; hier niet de bestaande meegenomen.
      :prod-games-person-day (det-prod-games-person-day lst-person-games)
      :lst-sol-person-info (det-lst-sol-person-info lst-person-games))))

; 18-9-2011 Baukelien wil dit jaar max 5 wedstrijden.
(defn handle-baukelien [sol]
  "User post processing function, such as changing the fitness based on specific requirements
   This one so that Baukelien has a max of 5 games."
  (let [n-games-baukelien (for [person (:lst-sol-person-info sol) 
                               :when (= (:referee-name person) "Baukelien Mulder")]
                            (:nreferee person)) ; this gives a list, so need the first item, if available.
        max-ok 5]
    (cond (empty? n-games-baukelien) sol
          (<= (first n-games-baukelien) max-ok) sol
          true (assoc sol :fitness
            (- (:fitness sol) (* 1000 (- (first n-games-baukelien) max-ok))))))) 

; deze nog dynamischer?
; make more flexible, so that a series of post-processing functions can be called.
; maybe also with a name, so chooseable with cmdline.
(defn user-post-process [sol]
  "Call user defined functions to possibly change solution, especially fitness"
  (-> sol
      handle-baukelien))

(defn add-statistics [vec-sol-referee note solnr-parent]
  "Return a solution hashmap, including statistics and fitness"
  (let [sol-values (det-sol-values *lst-inp-persons* vec-sol-referee)
        n-diff-referee (count (for [n (:lst-counts sol-values) :when (> n 0)] 1))
        lst-whinefactors (:lst-whinefactors sol-values)
        sol (assoc sol-values
            :vec-sol-referee vec-sol-referee
            :note note
            :solnr (new-sol-nr)
            :solnr-parent solnr-parent
            :fitness (calc-fitness (:prod-games-person-day sol-values) 
                                   (apply max (:lst-counts sol-values)) 
                                   n-diff-referee 
                                   (apply + lst-whinefactors) 
                                   (apply max lst-whinefactors))
            :max-referee (apply max (:lst-counts sol-values))
            :n-diff-referee n-diff-referee
            :sum-whinefactors (apply + lst-whinefactors)
            :max-whinefactors (max lst-whinefactors))]
        (user-post-process sol)))

; @note: beetje raar dat choose-random-referee met de game-id wordt aangeroepen, en niet met de game gegevens
; zelf. Zo gedaan omdat deze functie vanuit meerdere plekken wordt aangeroepen, en de gegevens niet overal bekend
; zijn. 
; @todo nog refactoren zodat het meer functioneel wordt, niet afhankelijk van global variables.
(defn make-solution [lst-input-games]
  (let [vec-sol-referee (vec (map #(choose-random-referee (:game-id %1)) lst-input-games))]
    (add-statistics vec-sol-referee "Initial solution" 0)))

(defn mutate-game [sol-referee]
  (choose-random-referee (:game-id sol-referee)))
        
(defn mutate-solution-step [vec-sol-referee]
  (let [rnd (rand-int (count vec-sol-referee))]
        (assoc vec-sol-referee rnd (mutate-game (get vec-sol-referee rnd)))))

; @todo de rand-int 2 waarde halen uit de command-line params. Hier ook een goede lib voor?
; bepaal randomwaarde 1 of 2, en muteer oplossing zo vaak
(defn mutate-solution [{:keys [vec-sol-referee solnr]}]            ; destructure the sol hashmap.   
  (let [new-vec-sol-referee
        (->> (iterate mutate-solution-step vec-sol-referee)        ; infinite lazy list of mutations
             (drop (inc (rand-int 2)))                             ; drop 1 or 2, these are the number of changes
             (first))]                                             ; and take the first.
     (add-statistics new-vec-sol-referee "Mutated game(s)" solnr)))  

; globals definieren met def, dan maar eenmalig een waarde toegekend (?)
; en krijgen pas een waarde bij uitvoeren, dus in andere functies niet bekend op compile time.
(defn init-globals []
  (def *lst-inp-games* (query-input-games))
  (def *lst-inp-persons* (det-lst-inp-persons)) 
  (def *ar-inp-games* 
    (zipmap (map :game-id *lst-inp-games*) *lst-inp-games*)))

; helper for can-find-better, use let, letfn?
(defn fitness-sol-game-change-referee [vec-sol-referee game-index referee]
  "@result fitness of sol if game with index game-index is refereed by referee"
  (-> (assoc vec-sol-referee game-index 
         (select-referee (get vec-sol-referee game-index) referee))
      (add-statistics "" 0)
      (:fitness)))
      
; helper for can-find-better, use let, letfn?
; @result max fitness als bij oplossing sol de game met index game-index wordt aangepast.
; lst-kan-fluiten uit *ar-inp-games* halen, niet uit vec-sol-referee
; vraag of je deze info ook niet bij oplossing wilt zetten, is toch read-only/immutable.
(defn max-fitness-sol-game-change [vec-sol-referee game-index]
  (apply max (map #(fitness-sol-game-change-referee vec-sol-referee game-index %) 
    (:lst-can-referee (*ar-inp-games* (:game-id (get vec-sol-referee game-index))))
    )))

; @note beetje map-reduce achtig: per game die je aanpast een andere functie, is dan parallel uit te voeren.
(defn can-find-better [sol]
  (> (apply max (map #(max-fitness-sol-game-change (:vec-sol-referee sol) %)
                     (range (count (:vec-sol-referee sol)))))
    (:fitness sol)))

; @todo parameterise minimal fitness for saving, now at -2000.
; @note 18-9-2011 set from -2000 to -200.000.
(defn handle-best-solution [proposition]
  (print-best-solution proposition *ar-inp-games* can-find-better)
  (log-solutions @proposition)
  (let [sol (first (:lst-solutions @proposition))]
    (if (> (:fitness sol) -200000)
      (save-solution sol))))

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
  (delete-old-proposition)
  (delete-logsolutions)
  
  (let [sol-args (clargon args
                   (optional ["-p" "--pop" :default 10 :doc "Population size"] #(Integer. %))
                   (optional ["-i" "--iter" :default 0 :doc "Max #Iterations"] #(Integer. %))
                   (optional ["-f" "--fitness" :default 100000 :doc "Fitness to reach"] #(Integer. %))
                   (optional ["-m" "--nmutations" :default 2 :doc "max #mutations in each generation"] #(Integer. %))
                   (optional ["--loglevel" :default "" :doc "warn, info or debug"])
                   (optional ["--print" :default "better" :doc "What to print"]))]
    (make-proposition sol-args))                  
  (close-global-db))  

;) ; deze als haakjes niet kloppen.
