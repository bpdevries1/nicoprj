(ns mediaweb.models.directory
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

(def-model-crud :obj-type :directory)

;; TODO hier evt een limit op zetten of paging maken.
(defn all-directories []
  (select directory (order :fullpath)
          (limit 30)
          (offset 0)))

;; map-flatten not needed here
(defn directory-by-id [id]
  (first (select directory
                 (where {:id (to-key id)}))))

#_(defn directory-by-id [id]
  (h/map-flatten
   (first (select directory
                  (where {:id (to-int id)})))))

(defn subdirs [id]
  (select directory (order :fullpath)
          (where {:parent_id (to-key id)})))

(defn files [id]
  (select file (order :filename)
          (where {:directory_id (to-key id)})))

