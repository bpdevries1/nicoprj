;( ; deze als haakjes niet kloppen.

; 20-2-2011 NdV voorlopig toch gewoon use met alles, want anders vage meldingen:
;scheidsclj.core=> (def lig (query-input-games))
;java.lang.ClassCastException: clojureql.core.RTable cannot be cast to java.util.Comparator (NO_SOURCE_FILE:34)

(ns scheidsclj.db
  (:use clojureql.core)
  ; vb:  [:use [clojure.contrib.math :exclude [sqrt]]]
  ; disj! gebruik ik nu, conj! waarschijnlijk later ook wel.
  ;(:use [clojureql.core :exclude (extend distinct conj! disj! case compile drop take sort )])
  ;(:require [clojureql.core :only (conj! disj!)])
  (:use [clj-time.core :exclude (extend)])
  (:use clj-time.format)
  (:use clj-time.coerce))

; mijn eerste eigen macro
; kan zo niet gebruiken, mogelijk omdat deze binnen een -> wordt gebruikt.
; krijg melding dat 5 args worden meegegeven.
(defmacro sel-where-eq [it1 it2]
  `(select (where (= ~it1 ~it2))))

(defn det-gepland-referee [referee-id]
  (let [result-set 
    @(-> (table :scheids)
         (join (table :zeurfactor) (where (and (= :scheids.scheids :zeurfactor.persoon)
                                                (= :scheids.speelt_zelfde_dag :zeurfactor.speelt_zelfde_dag))))
         (select (where (= :scheids.status "gemaild")))
         (select (where (= :scheids.scheids referee-id)))
         (project [:scheids.scheids :zeurfactor.factor]))]
    (hash-map :nfluit (count result-set)
              :zeurfactor (apply * (map :factor result-set)))))

; globals definieren met def, dan maar eenmalig een waarde toegekend (?)
; en krijgen pas een waarde bij uitvoeren, dus in andere functies niet bekend op compile time.
(defn det-lst-inp-personen []
  (->> @(-> (table :persoon)
            (project [:persoon.id :persoon.naam])
            (sort [:persoon.naam]))
    (map #(let [gepland-referee (det-gepland-referee (:id %1))]
             (hash-map :referee-id (:id %1)
                       :referee-naam (:naam %1)
                       :zeurfactor (:zeurfactor gepland-referee)
                       :nfluit (:nfluit gepland-referee))))))

; 20-2-2011 NdV getest met full namespace ref, en werkt.
(defn delete-oude-voorstel []
  (clojureql.core/disj! (table :scheids) (where (= :status "voorstel"))))  

; @result a string with the date part of datetime.
(defn datetime-to-date-old [datetime]
 (unparse (formatters :year-month-day) (from-date datetime)))

(defn query-lst-kan-fluiten [game-id]
  (->> @(-> (table :kan_wedstrijd_fluiten)
            (join (table :persoon) (where (= :persoon.id :kan_wedstrijd_fluiten.scheids)))
            (join (table :zeurfactor) (where (= :zeurfactor.persoon :persoon.id)))
            (select (where (= :kan_wedstrijd_fluiten.wedstrijd game-id)))
            (select (where (> :kan_wedstrijd_fluiten.waarde 0.2)))
            (select (where (= :zeurfactor.speelt_zelfde_dag :kan_wedstrijd_fluiten.speelt_zelfde_dag)))
            (project [:kan_wedstrijd_fluiten.scheids :kan_wedstrijd_fluiten.waarde 
                      :persoon.naam :zeurfactor.factor :kan_wedstrijd_fluiten.speelt_zelfde_dag]))
       (map #(hash-map :referee-id (:scheids %1) 
                       :referee-naam (:naam %1)
                       :zelfde-dag (:speelt_zelfde_dag %1)
                       :waarde (:waarde %1)
                       :zeurfactor (:factor %1)))))



(defn query-input-games []
  ; dubbele -> binnenste voor query opbouw, buitenste voor nabewerking
  (->> @(-> (table :wedstrijd)
           (outer-join (table :scheids) :left (where (= :scheids.wedstrijd :wedstrijd.id)))
           (select (where (= :wedstrijd.scheids_nodig 1)))
           (select (where (= :scheids.wedstrijd nil)))
           (project [:wedstrijd.id :wedstrijd.naam :date/wedstrijd.datumtijd])
           (sort [:wedstrijd.datumtijd]))
      (map #(hash-map :game-id (:id %1) 
                      :game-naam (:naam %1)
                      :datum (:datumtijd %1)
                      :lst-kan-fluiten (query-lst-kan-fluiten (:id %1))))))

(defn save-solution [sol]
  (delete-oude-voorstel)
  (println "Saving solution...")
  (clojureql.core/conj! (table :scheids) 
    (map #(hash-map
      :scheids (:referee-id %)
      :wedstrijd (:game-id %)
      :speelt_zelfde_dag (:zelfde-dag %)
      :status "voorstel") (:vec-opl-referee sol))))

(def db
 {:classname   "com.mysql.jdbc.Driver"
  :subprotocol "mysql"
  :user        "nico"
  :password    "pclip01;"
  :subname     "//localhost:3306/scheids"})

(open-global db) ; # geen connectie naam, gebruik default.

(defn open-global-db []
  (open-global db))

(defn close-global-db []
  (close-global))  

;) ; deze als haakjes niet kloppen.
