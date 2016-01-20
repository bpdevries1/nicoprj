;; ns-decl follows:
(ns mediaweb.endpoint.games
  (:require [compojure.core :refer :all]
            [mediaweb.views :as views]
            [mediaweb.views.wedstrijd :as vw]))

(defn games [config]
  (routes
   (GET "/wedstrijden" []
        (vw/wedstrijden))
   (GET "/wedstrijd/:id" [id]
        (vw/wedstrijd id))

   ;; mogelijk deze 3 als 1 route, en dan in vw/wedstrijd-update obv params kijken
   ;; welke je moet hebben. Maar nog niet zeker of dat beter is, dus nog even zo laten.
   (POST "/wedstrijd/:id/notes" [id & params]
         (vw/wedstrijd-notes-update id params))
   (POST "/wedstrijd/:id/datumtijd" [id & params]
         (vw/wedstrijd-datumtijd-update id params))
   (POST "/wedstrijd/:id/scheids" [id & params]
         (vw/wedstrijd-scheids-update id params))))

