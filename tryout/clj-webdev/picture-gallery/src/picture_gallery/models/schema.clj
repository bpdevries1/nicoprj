(ns picture-gallery.models.schema
  (:require [picture-gallery.models.db :refer :all]
            ;  [clojure.java.jdbc :as sql]
            [korma.db :refer [defdb transaction]]
            [korma.core :refer :all]))

; 16-11-2014 kan Lobos hiervoor gebruiken, nu even niet.


;; (defn create-users-table []
;;   (sql/with-connection db
;;      (sql/create-table
;;       :users
;;       [:id "varchar(32) PRIMARY KEY"]
;;       [:pass "varchar(100)"])))

;; (defn create-images-table []
;;   (sql/with-connection db
;;     (sql/create-table
;;      :images
;;      [:userid "varchar(32)"]
;;      [:name "varchar(100)"])))
