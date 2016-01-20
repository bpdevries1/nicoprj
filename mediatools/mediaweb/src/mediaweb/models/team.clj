;; ns-decl follows:
(ns mediaweb.models.team
  (:use korma.db korma.core)
  (:require [clojure.string :as string]
            [clj-time.core :as t]
            [clj-time.coerce :as tc]
            [clj-time.format :as tf]
            [libndv.core :as h]
            [libndv.coerce :refer [to-int to-key]]
            [libndv.crud :refer [def-model-crud]]
            [mediaweb.models.entities :refer :all]))

(defn all-teams []
  (select team (order :naam)))

(defn team-by-id [id]
  (h/map-flatten
   (first (select team
                  ;; in where clause to-int is still needed.
                  (where {:id (to-int id)})))))

;; 11-10-2015 NdV Of past deze beter in models_wedstrijd.clj?
(defn team-wedstrijden [id]
  (select wedstrijd
          (fields :id :naam :datumtijd :opmerkingen :lokatie)
          (where {:team (to-key id)})
          (with scheids (fields [:id :sid] :status)
                (with persoon (fields [:naam :pnaam] [:id :pid])))
          (order :datumtijd)))

(def-model-crud :obj-type :team)

