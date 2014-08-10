(ns liberator-service.routes.home
  (:require [compojure.core :refer :all]
            ;[liberator-service.views.layout :as layout]))
            [liberator.core
             :refer [defresource resource request-method-in]]))

;(defn home []
;  (layout/common [:h1 "Hello World!"]))

(defresource home
  ;allowed-methods [:get]
  :handle-ok "Hello World13!"
  :etag "fixed-etag2"
  :available-media-types ["text/plain"])

(defroutes home-routes
  (ANY "/" request home))

