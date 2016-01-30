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
;; TODO iets met limit te doen? Of clojure take 20 of zo
(defn all-files []
  (select file (order :filename)
          (limit 30)
          (offset 0)))

;; TODO: hier nu geen flatten in, want later ook refs naar books etc hierbij in een struct.
(defn file-by-id [id]
  (first (select file
                 (where {:id (to-key id)})
                 (with directory (fields [:id :dir_id] [:fullpath :dir_fullpath])))))

;; TODO: deze doet het niet, file wordt niet meegejoined. Wel in entities.clj de relatie beide kanten op gedefinieerd, dus onduidelijk nu. Mss has-one gebruiken.
#_(defn file-relfiles [id]
  "Return the relfile that file belongs to, if any"
  (select relfile
          (with file
                (where {:id (to-key id)}))))

#_(select relfile
        (with file
              (where {:id 548})))

;; deze nu alleen full select op relfile, geen join met file.
#_(sql-only (select relfile
                  (with file
                        (where {:id 548}))))

#_(sql-only (select file
                  (where {:id 548})
                  (with relfile
                        (fields [:id :rfid] :filename :relfolder :filesize :ts :notes))))

;; TODO: beetje jammer dat ik niet :id kan gebruiken, dit is file id. Tenzij je bij relfile
;; begint, maar dan rest query weer lastiger?
(defn file-relfiles [id]
  "Return the relfile that file belongs to, if any"
    (select file
            (where {:id (to-key id)})
            (with relfile
                  (fields [:id :rfid] :filename :relfolder :filesize :ts :notes))))

;; TODO: beetje jammer dat ik niet :id kan gebruiken, dit is file id. Tenzij je bij bookformat
;; begint, maar dan rest query weer lastiger?
(defn file-bookformats [id]
  "Return the bookformat that file belongs to, if any"
  (select file
          (where {:id (to-key id)})
          (with relfile
                (with bookformat
                      (fields [:id :bfid] :format :notes)))))

(defn file-books [id]
  "Return the book that file belongs to, if any"
  (select file
          (where {:id (to-key id)})
          (with relfile
                (with bookformat
                      (with book
                            (fields [:id :bid] :title :authors :pubdate :tags :notes))))))

(defn file-actions [id]
  (select action
          (where {:file_id (to-int id)})))


