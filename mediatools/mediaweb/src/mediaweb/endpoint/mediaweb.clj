(ns mediaweb.endpoint.mediaweb
  (:require [compojure.core :refer :all]
            [mediaweb.views :as views]
            [mediaweb.views.general :as vgen]))

(defn mediaweb-endpoint [config]
  (routes
   (GET "/" []
        (vgen/index))

   (POST "/search" [& params]
         (vgen/search-page params))
   ;; admin
   (GET "/admin" []
        (views/admin))))

