;; ns-decl follows:
(ns mediaweb.endpoint.persons
  (:require [compojure.core :refer :all]
            [mediaweb.views :as views])
  (:require
            [mediaweb.views.persoon :as vp]))

;; lines follow:
(defn persons [config]
  (routes
   ;; hieronder alles voor personen.
   (GET "/personen" []
        (vp/personen))

   (GET "/persoon/:id" [id]
        (vp/persoon id))
   (POST "/persoon/:id" [id & params]
         (vp/persoon-update id params))
   (POST "/persoon/:id/delete" [id & params]
         (vp/persoon-delete id params))

   (POST "/afwezig/:id" [id & params]
         (vp/afwezig-update id params))
   (POST "/afwezig/:id/delete" [id & params]
         (vp/afwezig-delete id params))

   ;; Deze nu alleen new en delete, geen update   
   ;; aanroepen als "kanteamfluiten/0" voor een nieuwe, persoon-id dan in params als :persoon
   (POST "/kan_team_fluiten/:id" [id & params]
         (vp/kan_team_fluiten-update id params))
   ;; persoon-id in de params, zodat je kan redirecten.
   (POST "/kan_team_fluiten/:id/delete" [id & params]
         (vp/kan_team_fluiten-delete id params))

   ;; alleen update voor costfactor (zijn er altijd 2, bij nieuwe persoon ook meteen maken)
   (POST "/costfactor/:id" [id & params]
         (vp/costfactor-update id params))

   ;; TODO mss ergens dashes door underscores vervangen op model niveau.
   ;; deze ook voor nieuw, met ptid = 0.
   (POST "/persoon_team/:id" [id & params]
         (vp/persoon_team-update id params))
   
   ;; delete hier ook met button en form-post, dus POST
   (POST "/persoon_team/:id/delete" [id & params]
         (vp/persoon_team-delete id params))))

