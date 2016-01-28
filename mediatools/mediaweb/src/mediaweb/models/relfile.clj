(ns mediaweb.models.relfile
  (:use korma.db korma.core)
  (:require [clojure.string :as string]
            [clj-time.core :as t]
            [clj-time.coerce :as tc]
            [clj-time.format :as tf]
            [libndv.core :as h]
            [libndv.coerce :refer [to-int to-key]]
            [libndv.crud :refer [def-model-crud]]
            [libndv.datetime :refer [parse-date-time]]
            [mediaweb.models.entities :refer :all]))

;; TODO: hier nu geen flatten in, want later ook refs naar books etc hierbij in een struct.
(defn relfile-by-id [id]
  (first (select relfile
                 (where {:id (to-int id)}))))

(def-model-crud :obj-type :relfile
  :pre-fn (fn [params] (-> params
                           (h/updates-in [:ts] parse-date-time))))


