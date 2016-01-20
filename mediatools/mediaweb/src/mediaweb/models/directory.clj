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

;; TODO hier evt een limit op zetten of paging maken.
(defn all-directories []
  (select directory (order :fullpath)
          (limit 30)
          (offset 0)))

(defn directory-by-id [id]
  (h/map-flatten
   (first (select directory
                  (where {:id (to-int id)})))))

;; TODO wat doet parse-date-time als 'ie al een datetime als param krijgt?
(def-model-crud :obj-type :directory
  :pre-fn (h/updates-in-fn [:ts_cet] parse-date-time))

