(ns mediaweb.endpoint.bookformats
  (:require [compojure.core :refer :all]
            [libndv.html :as h]
        ;;    [mediaweb.views :as views]
            [mediaweb.views.bookformat :as vb]
            ))

(h/def-with-default-routes "bookformat" "bookformats" "mediaweb.views.bookformat")

