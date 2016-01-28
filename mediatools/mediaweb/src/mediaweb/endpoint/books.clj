(ns mediaweb.endpoint.books
  (:require [compojure.core :refer :all]
            [libndv.html :as h]
        ;;    [mediaweb.views :as views]
        ;;    [mediaweb.views.book :as vb]
            ))

(h/def-with-default-routes "book" "books" "mediaweb.views.book")
