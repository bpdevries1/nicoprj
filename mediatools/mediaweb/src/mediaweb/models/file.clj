(ns mediaweb.models.file
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

(def-model-crud :obj-type :file
  :pre-fn (fn [params] (-> params
                           (h/updates-in [:ts] parse-date-time))))

(defn all-files []
  (select file (order :filename)
          (limit 50)
          (offset 0)))

;; TODO: hier nu geen flatten in, want later ook refs naar books etc hierbij in een struct.
(defn file-by-id [id]
  (first (select file
                 (where {:id (to-key id)})
                 (with directory (fields [:id :dir_id] [:fullpath :dir_fullpath])))))

(defn file-relfiles [id]
  (select relfile
          (join file (= :file.relfile_id :relfile.id))
          (where {:file.id (to-key id)})
          (limit 50)))

(defn file-bookformats [id]
  (select bookformat
          (join relfile (= :bookformat.id :relfile.bookformat_id))
          (join file (= :file.relfile_id :relfile.id))
          (where {:file.id (to-key id)})
          (limit 50)))

(defn file-books [id]
  (select book
          (join bookformat (= :bookformat.book_id :book.id))
          (join relfile (= :relfile.bookformat_id :bookformat.id))
          (join file (= :file.relfile_id :relfile.id))
          (where {:file.id (to-key id)})
          (limit 50)))

(defn file-actions [id]
  (select action
          (where {:file_id (to-int id)})
          (limit 50)))


