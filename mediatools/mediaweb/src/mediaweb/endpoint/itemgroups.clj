(ns mediaweb.endpoint.itemgroups
  (:require [compojure.core :refer :all]
            [libndv.html :as h]
            [mediaweb.views.itemgroup :as vi]))

(h/def-with-default-routes "itemgroup" "itemgroups" "mediaweb.views.itemgroup")
(h/def-with-default-routes "itemgroupquery" "itemgroupqueries" "mediaweb.views.itemgroup")
(h/def-with-default-routes "member" "members" "mediaweb.views.itemgroup")

