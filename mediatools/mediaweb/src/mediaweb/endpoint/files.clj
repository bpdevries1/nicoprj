(ns mediaweb.endpoint.files
  (:require [compojure.core :refer :all]
            ;; TODO: not really sure if the require below is really needed, and if so, if it's
            ;; only for the example file2 route.
            ;; test with (reset) is not conclusive.
            [mediaweb.views.file :as vf]
            [libndv.html :as h]))

;; Included example with extra route including params.
(h/def-with-default-routes "file" "files" "mediaweb.views.file"
  (GET "/file2/:id" [id]
       (mediaweb.views.file/file id)))

