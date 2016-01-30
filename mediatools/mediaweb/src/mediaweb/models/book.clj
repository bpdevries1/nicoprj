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

(defn book-relfiles [id]
  (select relfile
          (with bookformat
                (where {:book_id (to-key id)}))))

;; geeft meer velden terug dan je wilt, mss geen last van.
(defn book-files [id]
  (select file
          (with relfile
                (fields [:id :rfid])
                (with bookformat
                      (where {:book_id (to-key id)})
                      (fields [:id :bfid])))))

#_(defn book-relfiles [id]
  (select relfile
          (where {:bookformat_id
                  (select bookformat
                          (where {:book_id (to-key id)}))})))

(defn testje
  "Some tests, interactive, should be put in test namespace."
  []
  (book-relfiles 213)

  (select book (where {:id 213}))

  ;; (book->)format->relfile
  ;; book-format gebruiken, dan een map, maar lijkt niet handig, te veel queries.
  ;; relfile->format (naar boven)
  ;; sowieso in goede formaat voor presentatie, maar kan ook job zijn van de view, als dat in
  ;;   macro kan.

  (select bookformat
          (where {:book_id 213})
          (with relfile
                (with file)))

  ;; deze lijkt wel simpeler.
  (select relfile
          (with bookformat
                (where {:book_id 213})))

  ;; ook voor file?
  (select file
          (with relfile
                (fields [:id :rfid])
                (with bookformat
                      (where {:book_id 213})
                      (fields [:id :bfid]))))
  )
;; end-of-testje.
