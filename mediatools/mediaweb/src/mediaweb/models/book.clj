(ns mediaweb.models.book
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

(def-model-crud :obj-type :book)

;; TODO hier evt een limit op zetten of paging maken.
(defn all-books []
  (select book (order :title)))

(defn book-by-id [id]
  (h/map-flatten
   (first (select book
                  ;; in where clause to-int is still needed.
                  (where {:id (to-key id)})))))

(defn book-formats [id]
  (select bookformat
          (where {:book_id (to-key id)})))

