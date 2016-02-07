(ns mediaweb.models.itemgroup
  ;; TODO use vervangen door require, evt ook met :as , om update meldingen te voorkomen.
  (:use korma.db korma.core)
  (:require [clojure.string :as string]
            [clj-time.core :as t]
            [clj-time.coerce :as tc]
            [clj-time.format :as tf]
            [libndv.core :as h]
            [libndv.coerce :refer [to-int to-key]]
            [libndv.crud :refer [def-model-crud]]
            [mediaweb.models.entities :refer :all]))

(def-model-crud :obj-type :itemgroup)
(def-model-crud :obj-type :itemgroupquery)
(def-model-crud :obj-type :member)

;; TODO hier evt een limit op zetten of paging maken.
(defn all-itemgroups []
  (select itemgroup (order :name)))

(defn itemgroup-by-id [id]
  (h/map-flatten
   (first (select itemgroup
                  (where {:id (to-key id)})))))


