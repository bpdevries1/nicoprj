;( ; this one if parens don't match 

; 20-2-2011 NdV voorlopig toch gewoon use met alles, want anders vage meldingen:
;scheidsclj.core=> (def lig (query-input-games))
;java.lang.ClassCastException: clojureql.core.RTable cannot be cast to java.util.Comparator (NO_SOURCE_FILE:34)

(ns scheidsclj.db
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
    (hash-map :nfluit (count result-set)
              :whinefactor (apply * (map :factor result-set)))))

(defn det-lst-inp-persons []
  (->> @(-> (table :persoon)
            (project [:persoon.id :persoon.naam])
            (sort [:persoon.naam]))
    (map #(let [planned-referee (det-planned-referee (:id %1))]
             (hash-map :referee-id (:id %1)
                       :referee-name (:naam %1)
                       :whinefactor (:whinefactor planned-referee)
                       :nfluit (:nfluit planned-referee))))))

; 20-2-2011 NdV tested with full namespace ref, and it works.
(defn delete-old-proposition []
  (clojureql.core/disj! (table :scheids) (where (= :status "voorstel"))))  

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
  ; double --> and -> innermost for query building, outermost for post processing.
  (->> @(-> (table :wedstrijd)
           (outer-join (table :scheids) :left (where (= :scheids.wedstrijd :wedstrijd.id)))
           (select (where (= :wedstrijd.scheids_nodig 1)))
           (select (where (= :scheids.wedstrijd nil)))
           (project [:wedstrijd.id :wedstrijd.naam :date/wedstrijd.datumtijd])
           (sort [:wedstrijd.datumtijd]))
      (map #(hash-map :game-id (:id %1) 
                      :game-name (:naam %1)
                      :date (:datumtijd %1)
                      :lst-can-referee (query-lst-can-referee (:id %1))))))

(defn save-solution [sol]
  (delete-old-proposition)
  (println "Saving solution...")
  (clojureql.core/conj! (table :scheids) 
    (map #(hash-map
      :scheids (:referee-id %)
      :wedstrijd (:game-id %)
      :speelt_zelfde_dag (:same-day %)
      :status "voorstel") (:vec-sol-referee sol))))

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
