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
            [libndv.debug :refer [logline]]
            [mediaweb.models.entities :refer :all]))

(def-model-crud :obj-type :itemgroup)

(def-model-crud :obj-type :itemgroupquery
  :pre-fn #(h/updates-in % :itemgroup_id to-key))

(def-model-crud :obj-type :member
  :pre-fn #(h/updates-in % :itemgroup_id to-key))

;; TODO hier evt een limit op zetten of paging maken.
(defn all-itemgroups []
  (select itemgroup (order :name)))

(defn itemgroup-by-id [id]
  (h/map-flatten
   (first (select itemgroup
                  (where {:id (to-key id)})))))

(defn itemgroup-queries [id]
  (select itemgroupquery
          (where {:itemgroup_id (to-key id)})
          (order :type)))

;; TODO: flatten? Maar dan wel per element, dus map gebruiken.
;; TODO: algemeen maken, mss met deel-query die je ook bij tags en relation kunt gebruiken.
(defn itemgroup-members [id]
  ;;  (h/map-flatten)
  (logline "query" (sql-only (select member
                                     (join book (= :member.item_id :book.id))
                                     (fields :book.title)
                                     (where {:itemgroup_id (to-key id)})
                                     (order :book.title))))
  (logline "members" 
           (select member
                   (where {:itemgroup_id (to-key id)})
                   (order :title))))
