(ns mediaweb.endpoint.actions
  (:require [compojure.core :refer :all]
            [libndv.html :as h]
            [mediaweb.views.action :as va]))

(h/def-with-default-routes "action" "actions" "mediaweb.views.action")

