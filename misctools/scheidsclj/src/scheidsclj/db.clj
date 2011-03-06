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
(defn det-lst-inp-personen []
  (->> @(-> (table :persoon)
            (project [:persoon.id :persoon.naam])
            (sort [:persoon.naam]))
    (map #(let [gepland-scheids (det-gepland-scheids (:id %1))]
             (hash-map :scheids-id (:id %1)
                       :scheids-naam (:naam %1)
                       :zeurfactor (:zeurfactor gepland-scheids)
                       :nfluit (:nfluit gepland-scheids))))))

; 20-2-2011 NdV getest met full namespace ref, en werkt.
(defn delete-oude-voorstel []
  ; sql uitvoeren, waarsch db connectie nodig
  ;(disj! (table :scheids) (where (= :status "voorstel"))))
  (clojureql.core/disj! (table :scheids) (where (= :status "voorstel"))))  

; @result a string with the date part of datetime.
(defn datetime-to-date [datetime]
 (unparse (formatters :year-month-day) (from-date datetime)))

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



; @todo kan blijkbaar toch sql functies toepassen: :function/col 
; dit dan gebruiken ipv datetime-to-date
(defn query-input-games []
  ; dubbele -> binnenste voor query opbouw, buitenste voor nabewerking
  (->> @(-> (table :wedstrijd)
           (outer-join (table :scheids) :left (where (= :scheids.wedstrijd :wedstrijd.id)))
           (select (where (= :wedstrijd.scheids_nodig 1)))
           (select (where (= :scheids.wedstrijd nil)))
           (project [:wedstrijd.id :wedstrijd.naam :date/wedstrijd.datumtijd])
           (sort [:wedstrijd.datumtijd]))
      (map #(hash-map :wedstrijd-id (:id %1) 
                      :wedstrijd-naam (:naam %1)
                      :datum (:datumtijd %1)
                      :lst-kan-fluiten (query-lst-kan-fluiten (:id %1))))))

(defn query-input-games-old []
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

(defn save-solution [sol]
  (delete-oude-voorstel)
  (println "Saving solution...")
  (clojureql.core/conj! (table :scheids) 
    (map #(hash-map
      :scheids (:scheids-id %)
      :wedstrijd (:wedstrijd-id %)
      :speelt_zelfde_dag (:zelfde-dag %)
      :status "voorstel") (:vec-opl-scheids sol))))

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
