;( ; deze als haakjes niet kloppen.
(ns scheidsclj.core
  (:gen-class)
  (:use clojureql.core)
  (:use clj-time.core)
  (:use clj-time.format)
  (:use clj-time.coerce))

;(use 'clojureql.core) ; hoeft niet, hierboven is genoeg.

; @todo code splitsen in modules, vooral specifiek voor scheids, algemeen evolutionary programming, lib functions.

; globale vars, eenmaal gezet.
(declare *lst-inp-personen* *ar-inp-wedstrijden*)

; deze van Stuart Halloway op http://www.nofluffjuststuff.com/blog/stuart_halloway/2009/08/rifle_oriented_programming_with_clojure
; deze code mogelijk ook te gebruiken voor updaten van beste-oplossing.
(defn make-counter [init-val] 
  (let [c (atom init-val)] #(swap! c inc)))

(def sol-nr-counter (make-counter 0))

(defn new-sol-nr []
  (sol-nr-counter))

(defn scheids-afko [scheids-naam]
   (apply str (map first (re-seq #"[^\s]+" scheids-naam)))) 

; @todo 'globale' vars als beste-oplossing, die wel wordt aangepast.

; mijn eerste eigen macro
; kan zo niet gebruiken, mogelijk omdat deze binnen een -> wordt gebruikt.
; krijg melding dat 5 args worden meegegeven.
(defmacro sel-where-eq [it1 it2]
  `(select (where (= ~it1 ~it2))))

(defn delete-oude-voorstel []
  ; sql uitvoeren, waarsch db connectie nodig
  (disj! (table :scheids) (where (= :status "voorstel"))))  

; TODO: implementeren: is hier sql functie voor?
; ook nog even afhankelijk in welke vorm ik deze nodig heb.
; datetime.type = java.sql.Timestamp
; @result a string with the date part of datetime.
(defn datetime-to-date [datetime]
 (unparse (formatters :year-month-day) (from-date datetime)))

(defn datetime-to-date-old [datetime]
  datetime)

; TODO: maak nu een hash-map van een hash-map die bijna hetzelfde is.
; keuze: iets andere termen in hash-map, of column-rename toepassen.
; rename doet het niet goed, geen correcte mysql syntax.
(defn query-lst-kan-fluiten-fout [wedstrijd-id]
  ;(vector wedstrijd-id 2 3))
  @(-> (table :kan_wedstrijd_fluiten)
            (join (table :persoon) (where (= :persoon.id :kan_wedstrijd_fluiten.scheids)))
            (join (table :zeurfactor) (where (= :zeurfactor.persoon :persoon.id)))
            (select (where (= :kan_wedstrijd_fluiten.wedstrijd wedstrijd-id)))
            (select (where (> :kan_wedstrijd_fluiten.waarde 0.2)))
            (select (where (= :zeurfactor.speelt_zelfde_dag :kan_wedstrijd_fluiten.speelt_zelfde_dag)))
            (project [:kan_wedstrijd_fluiten.scheids :kan_wedstrijd_fluiten.waarde 
                      :persoon.naam :zeurfactor.factor :kan_wedstrijd_fluiten.speelt_zelfde_dag])
            (rename {:kan_wedstrijd_fluiten.scheids :scheids-id
                     :kan_wedstrijd_fluiten.waarde :waarde
                     :persoon.naam :scheids-naam
                     :zeurfactor.factor :zeurfactor
                     :kan_wedstrijd_fluiten.speelt_zelfde_dag :zelfde-dag})))

(defn query-lst-kan-fluiten [wedstrijd-id]
  ;(vector wedstrijd-id 2 3))
  (->> @(-> (table :kan_wedstrijd_fluiten)
            (join (table :persoon) (where (= :persoon.id :kan_wedstrijd_fluiten.scheids)))
            (join (table :zeurfactor) (where (= :zeurfactor.persoon :persoon.id)))
            (select (where (= :kan_wedstrijd_fluiten.wedstrijd wedstrijd-id)))
            (select (where (> :kan_wedstrijd_fluiten.waarde 0.2)))
            (select (where (= :zeurfactor.speelt_zelfde_dag :kan_wedstrijd_fluiten.speelt_zelfde_dag)))
            (project [:kan_wedstrijd_fluiten.scheids :kan_wedstrijd_fluiten.waarde 
                      :persoon.naam :zeurfactor.factor :kan_wedstrijd_fluiten.speelt_zelfde_dag]))
       (map #(hash-map :scheids-id (:scheids %1) 
                       :scheids-naam (:naam %1)
                       :zelfde-dag (:speelt_zelfde_dag %1)
                       :waarde (:waarde %1)
                       :zeurfactor (:factor %1)))))



(defn query-input-games []
  ; dubbele -> binnenste voor query opbouw, buitenste voor nabewerking
  ; todo: datumtijd naar date omzetten, kan dit binnen de query?
  (->> @(-> (table :wedstrijd)
           (outer-join (table :scheids) :left (where (= :scheids.wedstrijd :wedstrijd.id)))
           (select (where (= :wedstrijd.scheids_nodig 1)))
           (select (where (= :scheids.wedstrijd nil)))
           (project [:wedstrijd.id :wedstrijd.naam :wedstrijd.datumtijd])
           (sort [:wedstrijd.datumtijd]))
      (map #(hash-map :wedstrijd-id (:id %1) 
                      :wedstrijd-naam (:naam %1)
                      :datum (datetime-to-date (:datumtijd %1))
                      :lst-kan-fluiten (query-lst-kan-fluiten (:id %1))))))

(defn kan-scheidsen [wedstrijd-id]
  (map #(scheids-afko (:scheids-naam %1)) 
    (:lst-kan-fluiten (*ar-inp-wedstrijden* wedstrijd-id))))

(defn opl-scheids-to-string [opl-scheids]
  (str (:wedstrijd-naam opl-scheids) " (zd=" (:zelfde-dag opl-scheids) ") "
       (:scheids-naam opl-scheids) " (" (scheids-afko (:scheids-naam opl-scheids)) 
       ") (zf=" (:zeurfactor opl-scheids) "/" (:waarde opl-scheids) ") ("
       (apply str (interpose ", " (kan-scheidsen (:wedstrijd-id opl-scheids)))) ")" ))

(defn random-list [lst]
  (nth lst (rand-int (count lst))))

(defn choose-random-scheids [wedstrijd-id]
  (let [inp-wedstrijd (*ar-inp-wedstrijden* wedstrijd-id)
        inp-kan-fluiten (random-list (:lst-kan-fluiten inp-wedstrijd))]
    (merge (select-keys inp-wedstrijd [:wedstrijd-id :wedstrijd-naam :datum])
           (select-keys inp-kan-fluiten [:scheids-id :scheids-naam :zeurfactor :waarde :zelfde-dag]))))

; max_scheids is het belangrijkst, dan n_versch_scheids, dan som_zeurfactoren
; breng dus 4 dimensies in 1 dimensie!
; prod_wedstrijden_persoon_dag: 1..veel minder is beter, alles meer dan 1 is gewoon fout.
; wel bepalen hoe fout het is, zodat het beter kan worden, als bv 2 personen elk 2x op een dag moeten fluiten.
; max_scheids: 1..10 minder is beter
; n_versch_scheids: 1..20 meer is beter
; som_zeurfactoren: 0..10000 minder is beter
; door 1-maxwedstrperdag wordt dit deel 0 als het gewoon goed is, en negatief bij fouten.
; 19-9-2010 NdV max_scheids toch niet zo belangrijk, zelfdedag telt minder dan andere dag, en in zf al rekening mee gehouden.
; 19-9-2010 NdV zelfde geldt eigenlijk ook voor aantal verschillende scheidsen.
; 19-9-2010 NdV maar wel de lasten goed verdelen, dus max_zeurfactoren wel belangrijk.
; expr (1-$prod_wedstrijden_persoon_dag) * 100000 + (10-$max_scheids)*100 + $n_versch_scheids - (0.0001 * $som_zeurfactoren)
(defn calc-fitness [prod-wedstrijden-persoon-dag max-scheids n-versch-scheids som-zeurfactoren max-zeurfactoren]
  (- (* (- 1 prod-wedstrijden-persoon-dag) 100000)
     max-zeurfactoren
     (* 0.0001 som-zeurfactoren)))

; voor elke scheids: product van eerdere lijst met zeurfactoren (in lst-inp-personen) en huidige oplossing waar deze persoon scheids is
; hier nu niet gesorteerd, is niet nodig (?)
(defn det-lst-zeurfactoren-old [lst-inp-personen lst-opl-scheids]
  (map #(* (:zeurfactor %1)
           (apply * 
             (for [opl lst-opl-scheids :when (= (:scheids-id %1) (:scheids-id opl))]
               (/ (:zeurfactor opl) (:waarde opl)))))))

; bepaal per persoon welke wedstrijden deze fluit in de gemaakte oplossing
; input lijst van personen (hashmap)
; result lijst van personen (hashmap) aangevuld met lijst van wedstrijden per persoon
(defn det-persoon-wedstrijden [lst-inp-personen lst-opl-scheids]
  (map #(assoc %1 :lst-wedstrijden (for [opl lst-opl-scheids :when (= (:scheids-id %1) (:scheids-id opl))]
    opl)) lst-inp-personen))

; deze nog herschrijven met -> of ->>
; elke persoon heeft lijst van wedstrijden, elke wedstrijd is een hashmap. Maak per hashmap een nieuwe, zodat ze met merge-with opgeteld kunnen worden per persoon
(defn det-prod-wedstrijden-persoon-dag [lst-persoon-wedstrijden]
  (apply * 
    (map (fn [persoon] 
      (apply *
        (vals
          (apply merge-with + 
            (map #(hash-map (:datum %) 1) (:lst-wedstrijden persoon)))))) lst-persoon-wedstrijden)))
  
(defn det-lst-opl-persoon-info [lst-persoon-wedstrijden]
  (map #(assoc % 
              :nfluit (count (:lst-wedstrijden %))
              :zeurfactor (apply * (map :zeurfactor (:lst-wedstrijden %)))) lst-persoon-wedstrijden))

; bepaal sleutel waarden van de oplossing
; @result hashmap
(defn det-opl-values [lst-inp-personen lst-opl-scheids]
  (let [lst-persoon-wedstrijden (det-persoon-wedstrijden lst-inp-personen lst-opl-scheids)]
    (hash-map 
      :lst-zeurfactoren (map #(* (:zeurfactor %1)
                          (apply * (for [opl (:lst-wedstrijden %1)] 
                             (/ (:zeurfactor opl) (:waarde opl))))) lst-persoon-wedstrijden)
      :lst-aantallen (map #(count (:lst-wedstrijden %1)) lst-persoon-wedstrijden)
      :prod-wedstrijden-persoon-dag (det-prod-wedstrijden-persoon-dag lst-persoon-wedstrijden)
      :lst-opl-persoon-info (det-lst-opl-persoon-info lst-persoon-wedstrijden))))

(defn add-statistics [lst-opl-scheids note solnr-parent]
  (let [opl-values (det-opl-values *lst-inp-personen* lst-opl-scheids)
        n-versch-scheids (count (for [n (:lst-aantallen opl-values) :when (> n 0)] 1))
        lst-zeurfactoren (:lst-zeurfactoren opl-values)] 
    (assoc opl-values
            :lst-opl-scheids lst-opl-scheids
            :note note
            :solnr-parent solnr-parent
            :fitness (calc-fitness (:prod-wedstrijden-persoon-dag opl-values) 
                                   (apply max (:lst-aantallen opl-values)) 
                                   n-versch-scheids 
                                   (apply + lst-zeurfactoren) 
                                   (apply max lst-zeurfactoren))
            :max-scheids (max (:lst-aantallen opl-values))
            :n-versch-scheids n-versch-scheids
            :som-zeurfactoren (apply + lst-zeurfactoren)
            :max-zeurfactoren (max lst-zeurfactoren))))

; beetje raar dat choose-random-scheids met de wedstrijd-id wordt aangeroepen, en niet met de wedstrijd gegevens
; zelf. Zo gedaan omdat deze functie vanuit meerdere plekken wordt aangeroepen, en de gegevens niet overal bekend
; zijn. 
; @todo nog refactoren zodat het meer functioneel wordt, niet afhankelijk van global variables.
(defn make-solution [lst-input-games]
  (let [lst-opl-scheids (map #(choose-random-scheids (:wedstrijd-id %1)) lst-input-games)]
    (add-statistics lst-opl-scheids "Initial solution" 0)))

(defn det-gepland-scheids [scheids-id]
  (let [result-set 
    @(-> (table :scheids)
         (join (table :zeurfactor) (where (and (= :scheids.scheids :zeurfactor.persoon)
                                                (= :scheids.speelt_zelfde_dag :zeurfactor.speelt_zelfde_dag))))
         (select (where (= :scheids.status "gemaild")))
         (select (where (= :scheids.scheids scheids-id)))
         (project [:scheids.scheids :zeurfactor.factor]))]
    (hash-map :nfluit (count result-set)
              :zeurfactor (apply * (map :factor result-set)))))
          
; globals definieren met def, dan maar eenmalig een waarde toegekend (?)
; en krijgen pas een waarde bij uitvoeren, dus in andere functies niet bekend op compile time.
(defn init-globals [lst-input-games]
  (def *lst-inp-personen* 
    (->> @(-> (table :persoon)
              (project [:persoon.id :persoon.naam])
              (sort [:persoon.naam]))
      (map #(let [gepland-scheids (det-gepland-scheids (:id %1))]
               (hash-map :scheids-id (:id %1)
                         :scheids-naam (:naam %1)
                         :zeurfactor (:zeurfactor gepland-scheids)
                         :nfluit (:nfluit gepland-scheids))))))
  (def *ar-inp-wedstrijden* 
    (zipmap (map :wedstrijd-id lst-input-games) lst-input-games)))
                


(defn make-proposition [sol-args]
  (str "Make proposition" sol-args)) 

; kan wel declare gebruiken voor forward refs van functies, maar dan dubbel opnemen, dus ook niet handig.

(def db
 {:classname   "com.mysql.jdbc.Driver"
  :subprotocol "mysql"
  :user        "nico"
  :password    "pclip01;"
  :subname     "//localhost:3306/scheids"})

(open-global db) ; # geen connectie naam, gebruik default.

; @(table db :scheids)
; @(table :scheids) ; is ook mogelijk, na open-global
  
  
(defn -main [& args]
  (println "Welcome to scheidsclj! These are your args:" args)
  (println "TODO: implementatie van main")
  (open-global {:classname   "com.mysql.jdbc.Driver"
                :subprotocol "mysql"
                :user        "nico"
                :password    "pclip01;"
                :subname     "//localhost:3306/scheids"})
  (println (take 3 @(table :persoon)))
  (println (let [sol-args {:pop 10
                  :iter 0
                  :fitness 100000
                  :nmutations 2
                  :loglevel ""
                  :print "better"}]
    (make-proposition sol-args)))                  
  (close-global))  
  
(defn reload []
  (load-file "src/scheidsclj/core.clj"))  
  
  
(defn testje [par1]
  (println "Testje2 met par1=" par1))

; uit http://www.learningclojure.com/2010/03/conditioning-repl.html
(defn get-current-directory []
  (. (java.io.File. ".") getCanonicalPath))

;) ; deze als haakjes niet kloppen.
