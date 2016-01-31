(ns mediaweb.models.bookformat
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

(def-model-crud :obj-type :bookformat)

;; TODO hier evt een limit op zetten of paging maken.
(defn bookformat-by-id [id]
  (h/map-flatten
   (first (select bookformat
                  (where {:id (to-int id)})))))

;; hiermee idd weer alles
#_(defn bookformat-books [id]
  (select book
          (with bookformat
                (where {:id (to-key id)}))))

#_(defn bookformat-books [id]
  (select bookformat
          (where {:id (to-key id)})
          (with book
                (fields [:id :bid]))))

(defn bookformat-books [id]
  (select book
          (join bookformat (= :bookformat.book_id :book.id))
          (where {:bookformat.id (to-key id)})))

#_(bookformat-books 210)

(defn bookformat-relfiles [id]
  (select relfile
          (where {:bookformat_id (to-key id)})))

#_(bookformat-relfiles 210)

(defn bookformat-files [id]
  (select file
          (with relfile
                (where {:bookformat_id (to-key id)}))))

#_(bookformat-files 210)

