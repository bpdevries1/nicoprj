(ns teams.core
  (:gen-class)
  (:require [clojure.contrib.combinatorics :as comb]
            [clojure.set :as set2]
            [clojure.pprint :as pprint]))
  
(def teams [:h1 :h2 :h3 :h4 :d1 :d2 :d34 :d5])

;(def c1 (first (comb/combinations teams 4)))

(defn to-vl 
  "make a vroeg-laat hashmap out of (all) teams and a chosen combination of 4 teams"
  [teams combi]
  (into {} (map #(if ((set combi) %) [% :vroeg] [% :laat]) teams)))

;(def vl (to-vl teams c1))
; 30-5-2012 NdV H1 moet ook vroeg, omdat Eelco alleen vroeg training wil geven.
(def rules [["H4 vroeg" #(= :vroeg (% :h4))]
            ["H3 vroeg (Jeroen)" #(= :vroeg (% :h3))]
            ["H3 getraind door H2" #(not= (% :h3) (% :h2))]
            ["D1 getraind door H2 (Maarten)" #(not= (% :d1) (% :h2))]
            ["D2 getraind door H2 (Bertus)" #(not= (% :d2) (% :h2))]
            ["H2 getraind door H1 (Jan)" #(not= (% :h2) (% :h1))]
            ["H4 getraind door D1 (Saskia)" #(not= (% :h4) (% :d1))]
            ])


(defn problems
  "Find problems with a solution (vl) based on rules"
  [vl rules]
  (map first (filter (complement #((second %) vl)) rules)))

(defn solutions
  "determine possible solutions with a maximum of np problems"
  [teams rules np]
  (->> (comb/combinations teams 4)               ; give all 70 possibilities
       (map (partial to-vl teams))               ; make vl hashmap of the possibilities
       (map (fn [vl] [vl (problems vl rules)]))  ; determine list of problems for each solution, cannot use #() shortcut here in combi with [] constructor.
       (filter #(<= (count (second %)) np))))    ; keep only solutions with given maximum number of problems


(def sols (solutions teams rules 1))       

(defn print-sols [sols]
  (doseq [sol sols]
    (pprint/pprint (first sol))
    (println (str "Probleem:" (first (second sol))))
    (println "=======")))

