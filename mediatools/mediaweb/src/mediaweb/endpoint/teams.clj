(ns mediaweb.endpoint.teams
  (:require [compojure.core :refer :all]
            [mediaweb.views :as views]
            [mediaweb.views.team :as vt]))

(defn teams [config]
  (routes
   ;; teams  
   (GET "/teams" []
        (vt/teams))
   (GET "/team/:id" [id]
        (vt/team id))
   ;; dit zou POST /team/:id kunnen zijn, algemeen niet nodig.
   ;; de team-algemeen-update functie evt team-update noemen, wel vraag wat deze moet kunnen:
   ;; huidige doet echt alleen een update.
   ;; nieuw team? nu iets als /team/new in teams page, maar deze werkt (nog) niet.
   ;; idee mogelijk dat je update vanuit diverse plekken kunt aanroepen, functie kijkt wel welke
   ;; velden zijn gevuld.
   (POST "/team/:id" [id & params]
         (vt/team-update id params))
   (POST "/team/:id/delete" [id & params]
         (vt/team-delete id params))))

