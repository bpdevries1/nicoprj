;; ns-decl follows:
(ns mediaweb.models.persoon
  (:use korma.db korma.core)
  (:require [clojure.string :as string]
            [clj-time.core :as t]
            [clj-time.coerce :as tc]
            [clj-time.format :as tf]
            [libndv.core :as h]
            [libndv.coerce :refer [to-int to-key]]
            [libndv.datetime :refer [parse-date]]
            [libndv.debug :refer [logline]]
            [libndv.crud :refer [def-model-crud]]
            [mediaweb.models.entities :refer :all]))

;;; personen - select
;;; personen boven wedstrijden, want persoon-by-name gebruikt in wedstrijd.
;; TODO with persoon_team stuk gebruikt in diverse queries, in los stuk te zetten?
(defn all-personen []
  (map h/map-flatten
       (select persoon
               ;; :telnrs
               (fields :id :naam :afko :email :telnrs :nevobocode :opmerkingen)
               (order :naam)
               (with persoon_team (fields [:id :ptid])
                     (where {:soort "speler"})
                     (with team (fields [:naam :tnaam] [:id :tid]))))))

(defn persoon-by-name [name]
  (h/map-flatten
   (first
    (select persoon
            (where {:naam name})
            (with persoon_team
                  (where {:soort "speler"})
                  (with team (fields [:naam :team] [:id :tid])))))))

(defn persoon-by-id [id]
  (h/map-flatten
   (first (select persoon
                  (where {:id (to-int id)}) ; in where clause to-int is still needed.
                  (with persoon_team (fields)
                        (where {:soort "speler"})
                        (with team (fields [:naam :tnaam] [:id :tid])))))))

(defn persoon-afwezig [id]
  (select afwezig
          (where {:persoon (to-int id)})
          (order :eerstedag)))

(defn persoon-kanteamfluiten [id]
  (select kan_team_fluiten
          (where {:persoon (to-int id)})
          (with team (fields [:naam :teamnaam] [:id :tid]))
          (order :teamnaam)))

(defn persoon-costfactor [id]
  (select costfactor
          (where {:persoon (to-key id)})
          (order :speelt_zelfde_dag)))

(def-model-crud :obj-type :persoon
  :insert-post-fn (fn [id]
                    (insert costfactor
                            (values [{:persoon id :speelt_zelfde_dag 0 :factor 8}
                                     {:persoon id :speelt_zelfde_dag 1 :factor 2}]))))

(def-model-crud :obj-type :afwezig
  :pre-fn (fn [params] (if (nil? (:laatstedag params))
                         (assoc params :laatstedag (:eerstedag params))
                         params)))

(defn replace-nil
  "replace value of k1 in map m with value of k2 iff value of k1 is nil"
  [m k1 k2]
  (assoc m k1 (or (k1 m) (k2 m))))

(def-model-crud :obj-type :afwezig
  :pre-fn (fn [params] (-> params
                           (h/updates-in [:eerstedag :laatstedag] parse-date)
                           (replace-nil :laatstedag :eerstedag))))
(def-model-crud :obj-type :kan_team_fluiten)
(def-model-crud :obj-type :costfactor)

(defn persoon-teams [pid]
  (select persoon_team
          (where {:persoon (to-key pid)})
          (with team (fields [:naam :teamnaam] [:id :tid]))
          (order :teamnaam)))

(def-model-crud :obj-type :persoon_team)

;; bij nieuwe persoon is pid nil, dan geen wedstrijden.
(defn scheids-wedstrijden [pid]
  (if pid
    (select wedstrijd
                  (fields :id :naam :datumtijd :opmerkingen :lokatie)
                  (with scheids (fields [:id :sid] :status)
                        (where {:persoon (to-key pid)})      
                        (with persoon (fields [:naam :pnaam] [:id :pid])))
                  (order :datumtijd))))


