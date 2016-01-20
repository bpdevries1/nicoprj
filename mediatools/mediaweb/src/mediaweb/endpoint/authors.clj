(ns mediaweb.endpoint.authors
  (:require [compojure.core :refer :all]
            [mediaweb.views :as views]
            [mediaweb.views.author :as va]))

(defn authors [config]
  (routes
   (GET "/authors" []
        (va/authors))
   (GET "/author/:id" [id]
        (va/author id))
   (POST "/author/:id" [id & params]
         (va/author-update id params))
   (POST "/author/:id/delete" [id & params]
         (va/author-delete id params))))


