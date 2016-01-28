(ns mediaweb.endpoint.actions
  (:require [compojure.core :refer :all]
            [libndv.html :as h]
  ;;          [mediaweb.views :as views]
  ;;          [mediaweb.views.action :as va]
            ))

#_(defn actions [config]
  (routes
   (GET "/actions" []
        (va/actions))
   (GET "/action/:id" [id]
        (va/action id))
   (POST "/action/:id" [id & params]
         (va/action-update id params))
   (POST "/action/:id/delete" [id & params]
         (va/action-delete id params))))

(h/def-with-default-routes "action" "actions" "mediaweb.views.action")

