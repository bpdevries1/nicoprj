(ns mediaweb.models.relfile
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

(def-model-crud :obj-type :relfile
  :pre-fn (fn [params] (-> params
                           (h/updates-in [:ts] parse-date-time))))

;; TODO: hier nu geen flatten in, want later ook refs naar books etc hierbij in een struct.
(defn relfile-by-id [id]
  (first (select relfile
                 (where {:id (to-int id)}))))

(defn relfile-books [id]
  (select book
          (join bookformat (= :bookformat.book_id :book.id))
          (join relfile (= :relfile.bookformat_id :bookformat.id))
          (where {:relfile.id (to-key id)})))

(relfile-books 210)

#_(defn relfile-books [id]
  (select relfile
          (fields [:relfile.id :rfid] [:relfile.notes :rfnotes])
          (where {:id (to-key id)})
          (with bookformat
                (fields [:bookformat.id :bfid] [:bookformat.notes :bfnotes])
                (with book
                      (fields [:book.id :bid] [:book.notes :bnotes])))))

#_(relfile-books 210)

#_(sql-only (select relfile
                  (fields [:relfile.id :rfid] [:relfile.notes :rfnotes])
                  (where {:id 210})
                  (with bookformat
                        (fields [:bookformat.id :bfid] [:bookformat.notes :bfnotes])
                        (with book
                              (fields [:book.id :bid] [:book.notes :bnotes])))))

#_(sql-only (select relfile
                  (fields [:relfile.id :rfid] [:relfile.notes :rfnotes])
                  (where {:id 210})))
;; deze ook fout, selecteert alle velden. Combi van select/fields is dus buggy.


#_(select bookformat
        (with relfile
              (where {:relfile.id 210})))
;; => fout, alle bookformats. Mss omdat with een left-outer-join is.
;; kan zijn omdat (with relfile) een losse query oplevert, en dus niet in de hoofdquery zit.

#_(sql-only (select bookformat
                  (with relfile
                        (where {:relfile.id 210}))))

#_(select bookformat
        (join relfile (= :relfile.bookformat_id :bookformat.id))
        (where {:relfile.id 210}))
;; => lijkt goed.

#_(sql-only (select bookformat
                  (join relfile (= :relfile.bookformat_id :bookformat.id))
                  (where {:relfile.id 210})))
;; => weer een join, wel weer een left join.

(defn relfile-bookformats [id]
  (select bookformat
          (join relfile (= :relfile.bookformat_id :bookformat.id))
          (where {:relfile.id (to-key id)})))

#_(relfile-bookformats 210)

(defn relfile-files [id]
  (select file
          (where {:relfile_id (to-key id)})))


