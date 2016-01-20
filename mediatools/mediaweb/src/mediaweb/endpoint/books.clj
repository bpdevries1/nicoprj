(ns mediaweb.endpoint.books
  (:require [compojure.core :refer :all]
            [mediaweb.views :as views]
            [mediaweb.views.book :as vb]))

(defn books [config]
  (routes
   (GET "/books" []
        (vb/books))
   (GET "/book/:id" [id]
        (vb/book id))
   (POST "/book/:id" [id & params]
         (vb/book-update id params))
   (POST "/book/:id/delete" [id & params]
         (vb/book-delete id params))))


