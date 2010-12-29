(ns bindings.home.index
  (:use conjure.core.binding.base
        helpers.home-helper)
  (:require [models.message :as message]))

(def-binding []
  (let [id (:id (conjure.core.server.request/record))
        message (if id (message/get-record id) (message/find-first))] 
    (with-home-request-map
      (render-view message (message/find-records ["true"])))))
