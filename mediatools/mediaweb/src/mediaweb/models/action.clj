(ns mediaweb.models.action
  (:use korma.db korma.core)
  (:require [clojure.string :as string]
            [clj-time.core :as t]
            [clj-time.coerce :as tc]
            [clj-time.format :as tf]
            [libndv.core :as h]
            [libndv.coerce :refer [to-int to-key]]
            [libndv.datetime :refer [format-date-time parse-date-time]]
            [libndv.crud :refer [def-model-crud]]
            [mediaweb.models.entities :refer :all]))

;; TODO hier evt een limit op zetten of paging maken.
(defn all-actions []
  (select action
          (order :create_ts)
          (limit 50)))

(defn action-by-id [id]
  (h/map-flatten
   (first (select action
                  ;; in where clause to-int is still needed.
                  (where {:id (to-int id)})))))

;; TODO wat doet parse-date-time als 'ie al een datetime als param krijgt?
(def-model-crud :obj-type :action
  :pre-fn (h/updates-in-fn [:ts_cet] parse-date-time))

