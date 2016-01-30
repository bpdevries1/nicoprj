(ns mediaweb.endpoint.directories
  (:require [compojure.core :refer :all]
            [libndv.html :as h]
;;            [mediaweb.views :as views]
            [mediaweb.views.directory :as vd]
            ))

#_(defn directories [config]
  (routes
   (GET "/directories" []
        (vd/directories))
   (GET "/directory/:id" [id]
        (vd/directory id))
   (POST "/directory/:id" [id & params]
         (vd/directory-update id params))
   (POST "/directory/:id/delete" [id & params]
         (vd/directory-delete id params))))

(h/def-with-default-routes "directory" "directories" "mediaweb.views.directory")

