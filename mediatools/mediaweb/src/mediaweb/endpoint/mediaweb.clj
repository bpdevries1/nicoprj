(ns mediaweb.endpoint.mediaweb
  (:require [compojure.core :refer :all]
            [mediaweb.views :as views]
            [mediaweb.views.general :as vg]))

(defn mediaweb-endpoint [config]
  (routes
   (GET "/" []
        (vg/index))

   ;; admin
   (GET "/admin" []
        (views/admin))))

