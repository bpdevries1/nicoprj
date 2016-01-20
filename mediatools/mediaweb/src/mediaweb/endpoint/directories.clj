(ns mediaweb.endpoint.directories
  (:require [compojure.core :refer :all]
            [mediaweb.views :as views]
            [mediaweb.views.directory :as vd]))

;; TODO: hier een macro voor, voor de default acties? Wel mogelijkheid andere acties toe te voegen.
(defn directories [config]
  (routes
   (GET "/directories" []
        (vd/directories))
   (GET "/directory/:id" [id]
        (vd/directory id))
   (POST "/directory/:id" [id & params]
         (vd/directory-update id params))
   (POST "/directory/:id/delete" [id & params]
         (vd/directory-delete id params))))


