(ns mediaweb.models.file
  (:use korma.db korma.core)
  (:require [clojure.string :as string]
            [clj-time.core :as t]
            [clj-time.coerce :as tc]
            [clj-time.format :as tf]
            [libndv.core :as h]
            [libndv.coerce :refer [to-int to-key]]
            [libndv.crud :refer [def-model-crud]]
            [mediaweb.models.entities :refer :all]))

;; TODO iets met limit te doen? Of clojure take 20 of zo
(defn all-files []
  (select file (order :filename)
          (limit 30)
          (offset 0)))

(defn file-by-id [id]
  (h/map-flatten
   (first (select file
                  ;; in where clause to-int is still needed.
                  (where {:id (to-int id)})))))

(def-model-crud :obj-type :file)

(defn file-actions [id]
  (select action
          (where {:file_id (to-int id)})))


