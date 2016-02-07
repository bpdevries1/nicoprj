(ns mediaweb.endpoint.itemgroups
  (:require [compojure.core :refer :all]
            [libndv.html :as h]
        ;;    [mediaweb.views :as views]
            [mediaweb.views.itemgroup :as vi]
            ))

(h/def-with-default-routes "itemgroup" "itemgroups" "mediaweb.views.itemgroup")
