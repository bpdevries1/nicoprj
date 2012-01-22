;( ; this one if parens don't match 

(ns scheidsclj.db
  (:refer-clojure :exclude [take drop sort distinct compile conj! disj! case]) ; 31-12-2011 deze constructie in SocialSite gezien (Lau Jensen), ook case erbij gezet.
  ;(:use scheidsclj.break) ; error if kept within (ns macro)
  (:use clojureql.core) 
  (:use [clj-time.core :exclude (extend)])
  (:use clj-time.format)
  (:use clj-time.coerce))

(defn det-planned-referee [referee-id]
  (let [result-set 
    @(-> (table :scheids)
         (join (table :zeurfactor) (where (and (= :scheids.scheids :zeurfactor.persoon)
                                                (= :scheids.speelt_zelfde_dag :zeurfactor.speelt_zelfde_dag))))
         (select (where (= :scheids.status "gemaild")))
         (select (where (= :scheids.scheids referee-id)))
         (project [:scheids.scheids :zeurfactor.factor]))]
    (hash-map :nreferee (count result-set)
              :whinefactor (apply * (map :factor result-set)))))

; @todo 31-12-2011 deze map-hashmap constructie mss handiger te doen, zie Lau Jensen over Uncle Bob.
(defn det-lst-inp-persons []
  (->> @(-> (table :persoon)
            (project [:persoon.id :persoon.naam])
            (sort [:persoon.naam]))
    (map #(let [planned-referee (det-planned-referee (:id %1))]
             (hash-map :referee-id (:id %1)
                       :referee-name (:naam %1)
                       :whinefactor (:whinefactor planned-referee)
                       :nreferee (:nreferee planned-referee))))))

; 20-2-2011 NdV tested with full namespace ref, and it works.
(defn delete-old-proposition []
  (clojureql.core/disj! (table :scheids) (where (= :status "voorstel"))))  

; 27-3-2011 NdV added where 1=1, otherwise an error
(defn delete-logsolutions []
  (clojureql.core/disj! (table :logsolution) (where (= 1 1))))

; @todo also english in DB, then the conversion (map #(hash-map)) is not necessary.
(defn query-lst-can-referee [game-id]
  (->> @(-> (table :kan_wedstrijd_fluiten)
            (join (table :persoon) (where (= :persoon.id :kan_wedstrijd_fluiten.scheids)))
            (join (table :zeurfactor) (where (= :zeurfactor.persoon :persoon.id)))
            (select (where (= :kan_wedstrijd_fluiten.wedstrijd game-id)))
            (select (where (> :kan_wedstrijd_fluiten.waarde 0.2)))
            (select (where (= :zeurfactor.speelt_zelfde_dag :kan_wedstrijd_fluiten.speelt_zelfde_dag)))
            (project [:kan_wedstrijd_fluiten.scheids :kan_wedstrijd_fluiten.waarde 
                      :persoon.naam :zeurfactor.factor :kan_wedstrijd_fluiten.speelt_zelfde_dag]))
       (map #(hash-map :referee-id (:scheids %1) 
                       :referee-name (:naam %1)
                       :same-day (:speelt_zelfde_dag %1)
                       :value (:waarde %1)
                       :whinefactor (:factor %1)))))



(defn query-input-games []
  ; double ->> and -> innermost for query building, outermost for post processing.
  ; does not select games where a scheids-record exists, even if it has status "voorstel"
  (->> @(-> (table :wedstrijd)
           (outer-join (table :scheids) :left (where (= :scheids.wedstrijd :wedstrijd.id)))
           (select (where (= :wedstrijd.scheids_nodig 1)))
           (select (where (= :scheids.wedstrijd nil)))
           (project [:wedstrijd.id :wedstrijd.naam :date/wedstrijd.datumtijd])
           (sort [:wedstrijd.datumtijd]))
      (map #(hash-map :game-id (:id %1) 
                      :game-name (:naam %1)
                      :date ((keyword "date(wedstrijd.datumtijd)") %1)
                      :lst-can-referee (query-lst-can-referee (:id %1))))))

(defn save-solution [{:keys [vec-sol-referee]}]
  (delete-old-proposition)
  (println "Saving solution...")
  (clojureql.core/conj! (table :scheids) 
    (map #(hash-map
      :scheids (:referee-id %)
      :wedstrijd (:game-id %)
      :speelt_zelfde_dag (:same-day %)
      :status "voorstel") vec-sol-referee)))

(defn save-solution-old [sol]
  (delete-old-proposition)
  (println "Saving solution...")
  (clojureql.core/conj! (table :scheids) 
    (map #(hash-map
      :scheids (:referee-id %)
      :wedstrijd (:game-id %)
      :speelt_zelfde_dag (:same-day %)
      :status "voorstel") (:vec-sol-referee sol))))


(defn log-solutions [{:keys [lst-solutions iteration]}]
  "Log the event of a better solution in the database, for further algorithm analysis"
  ; (break)
  (println "*********** Logging iteration info to database ************")
  (clojureql.core/conj! (table :logsolution)
    (map #(hash-map
      :iteration iteration
      :solnr (:solnr %1)
      :solnrparent (:solnr-parent %1)
      :fitness (:fitness %1)) lst-solutions)))
        
(def db
 {:classname   "com.mysql.jdbc.Driver"
  :subprotocol "mysql"
  :user        "nico"
  :password    "pclip01;"
  :subname     "//localhost:3306/scheids"})

(open-global db) ; # geen connectie name, gebruik default.

(defn open-global-db []
  (open-global db))

(defn close-global-db []
  (close-global))  

;) ; if parens don't match.
