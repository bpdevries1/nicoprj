(ns mediaweb.views.team
  (:require
   [hiccup.page :refer [html5 include-js include-css]]
   [hiccup.form :refer [form-to text-field submit-button text-area
                        drop-down hidden-field]]
   [ring.util.response :as response]
   [mediaweb.models :as models]
   [libndv.core :as h]
   [potemkin.macros :as pm]
   [libndv.crud :refer [def-view-crud]]
   [libndv.datetime :refer [format-date-time]]
   [libndv.html :refer [def-object-form def-object-page def-page 
                                    def-objects-form]]
   [mediaweb.models.team :as mt]
   [mediaweb.views.general :refer :all]))

;; TODO team-add functionaliteit maken, had ik nog helemaal niet.
(def-objects-form teams-form teams t
  {:model-read-fn (fn [_] (mt/all-teams)),
   :actions #{:add-get},
   :row-type :team,
   :columns [{:name "Naam", :width 10, :form (team-href (:id t) (:naam t))}
             {:name "Scheids nodig", :width 10, :form (:scheids_nodig t)}
             {:name "Opmerkingen", :width 80, :form (:opmerkingen t)}]})

(def-page teams
  {:base-page-fn base-page
   :page-name "Teams"
   :page-fn teams-form})

(def-object-form team-form team
  {:obj-type :team
   :fields [{:label "Naam" :field :naam}
            {:label "Scheids-nodig" :field :scheids_nodig}
            {:label "Opmerkingen" :field :opmerkingen}]})

(def-objects-form team-wedstrijden t w
  {:main-type :team,
   :row-type :wedstrijd,
   :model-read-fn mt/team-wedstrijden,
   :actions {},
   :columns [{:name "Datum/Tijd" :width 20 :form (format-date-time (:datumtijd w))}
             {:name "Wedstrijd" :width 40 :form (wedstrijd-href (:id w) (:opmerkingen w))}
             {:name "Scheidsrechter" :width 30
              :form (if (= "uit" (:lokatie w))
                      "Uit wedstrijd"
                      (persoon-href (:pid w) (:pnaam w)))}
             {:name "Status" :width 10 :form (:status w)}]})

;; TODO als je meer dan 1 actie wilt, dan past dit zo niet. Dan mss meerdere submit buttons,
;; maar waarschijnlijk meerdere forms nodig.
(def-object-form acties-form team
  {:obj-type :team
   :obj-part :delete
   :submit-label "Verwijder team"})

(def-object-page team
  {:base-page-fn base-page
   :page-name "Team"
   :parts [{:title "Algemeen" :part-fn team-form}
           {:title "Wedstrijden" :part-fn team-wedstrijden}
           {:title "Acties" :part-fn acties-form}]
   :model-read-fn mt/team-by-id
   :name-fn :naam
   :debug true})

;; TODO lijst van personen en of ze dit team kunnen/willen fluiten.
;; Soort dwars doorsnede van de tabel bij persoon.

;; TODO lijst van personen die in dit team zitten (en scheids zijn).

(def-view-crud :obj-type :team
  :redir-update-type :team
  :redir-delete-type :teams
  :model-ns mediaweb.models.team)

