(ns mediaweb.endpoint.files
  (:require [compojure.core :refer :all]
            [mediaweb.views.file :as vf]))

(defn files [config]
  (routes
   (GET "/files" []
        (vf/files))
   (GET "/file/:id" [id]
        (vf/file id))
   (POST "/file/:id" [id & params]
         (vf/file-update id params))
   (POST "/file/:id/delete" [id & params]
         (vf/file-delete id params))))

