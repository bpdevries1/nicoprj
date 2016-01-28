(ns mediaweb.endpoint.relfiles
  (:require [compojure.core :refer :all]
            [libndv.html :as h]
            ;; this req does seem to be necessary.
            ;; TODO: load class from string-name?
            [mediaweb.views.relfile :as vr]))

;; Included example with extra route including params.
(h/def-with-default-routes "relfile" "relfiles" "mediaweb.views.relfile")

