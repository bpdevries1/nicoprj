(ns mediaweb.views.persoon
  (:require
   [hiccup.page :refer [html5 include-js include-css]]
   [hiccup.form :refer [form-to text-field submit-button text-area
                        drop-down hidden-field]]
   [ring.util.response :as response]
   [mediaweb.models :as models]
   [libndv.core :as h]
   [potemkin.macros :as pm])
  (:require
   [libndv.coerce :refer [to-key]]
   [libndv.datetime :refer [format-date format-date-time parse-date]]
   [libndv.html :refer [def-object-form def-object-page def-objects-form
                                    def-page]]
   [libndv.crud :refer [def-view-crud]]
   [mediaweb.models.persoon :as mp]
   [mediaweb.models.team :as mt]
   [mediaweb.views.general :refer :all]))

(def-objects-form personen-form personen p
  {:model-read-fn (fn [_] (mp/all-personen)),
   :actions #{:add-get},
   :row-type :persoon,
   :columns
   [{:name "Naam (afko)",
     :width 20,
     :form (persoon-href (:id p) (str (:naam p) " (" (:afko p) ")"))}
    {:name "E-mail", :width 10, :form (:email p)}
    {:name "Telnrs", :width 20, :form (:telnrs p)}
    {:name "Team", :width 10, :form (team-href (:tid p) (:tnaam p))}
    {:name "Nevobocode", :width 10, :form (:nevobocode p)}
    {:name "Opmerkingen", :width 30, :form (:opmerkingen p)}]})


(def-page personen
  {:base-page-fn base-page
   :page-name "Personen"
   :page-fn personen-form})

;;;;;; alles hieronder van enkelvoud persoon ;;;;;;;;
(def-object-form persoon-form person
  {:obj-type :persoon
   :fields [{:label "Naam" :field :naam}
            {:label "Afko" :field :afko}
            {:label "E-mail" :field :email}
            {:label "Tel nrs" :field :telnrs}
            {:label "Nevobo-code" :field :nevobocode}
            {:label "Opmerkingen" :field :opmerkingen}]})

(def-objects-form persoon-teams-form p pt
  {:main-type :persoon,
   :row-type :persoon_team,
   :model-read-fn mp/persoon-teams,
   :columns
   [{:name "Team" :width 10 :form (drop-down
                                   :team
                                   (concat [["" "0"]] (map (juxt :naam :id) (mt/all-teams)))
                                   (:tid pt))}
    {:name "Soort" :width 30 :form {:field :soort}}]})

(def-objects-form persoon-afwezig-form p afw
  {:main-type :persoon,
   :row-type :afwezig,
   :model-read-fn mp/persoon-afwezig,
   :columns
   [{:name "Eerste dag",
     :width 1,
     :form {:label "dd-mm-yyyy", :field :eerstedag, :format-fn format-date}}
    {:name "Laatste dag",
     :width 1,
     :form {:label "dd-mm-yyyy", :field :laatstedag, :format-fn format-date}}
    {:name "Opmerkingen", :width 1, :form {:field :opmerkingen}}]})

(def-objects-form kan-team-fluiten-form p ktf
  {:main-type :persoon
   :row-type :kan_team_fluiten
   :model-read-fn mp/persoon-kanteamfluiten
   :columns [{:name "Team" :width 10
              :form (drop-down :team
                               (concat [["" "0"]] (map (juxt :naam :id) (mt/all-teams)))
                               (:tid ktf))}
             {:name "Waarde", :width 10 :form {:field :waarde}}
             {:name "Opmerkingen", :width 10 :form {:field :opmerkingen}}]})

(defn to-zelfdedag-string [speelt_zelfde_dag]
  (if (= 0 speelt_zelfde_dag)
    "Niet zelfde dag"
    "Speelt zelfde dag"))

;; TODO met minder knoppen lijkt uitlijning wat vaag te gaan, combi van volledige breedte moet
;; gebruikt (bij eigen teams bv niet), edit-box heeft standaard/maximale breedte (mogelijk instelbaar). En mss toch iets met de nil's als resultaat van de macro expansie.
;; bij orig functie zonder macro was het al zo, dus zal niets met de nils in de expansie te
;; maken hebben, maar met table-width en edit-box width. Table column width ook wel wat raar, tot 3 lijkt het gelijk aan 1 te zijn, vanaf 4 weer andere dingen.
(def-objects-form costfactor-form p cf
  {:main-type :persoon,
   :row-type :costfactor,
   :model-read-fn mp/persoon-costfactor,
   :actions #{:edit},
   :columns
   [{:name "Wanneer",
     :width 20,
     :form (to-zelfdedag-string (:speelt_zelfde_dag cf))}
    {:name "Factor", :width 1, :form {:field :factor}}
    {:name "Opmerkingen", :width 3, :form {:field :opmerkingen}}]})

(def-objects-form scheids-wedstrijden p w
  {:main-type :persoon,
   :row-type :wedstrijd,
   :model-read-fn mp/scheids-wedstrijden,
   :actions {},
   :columns
   [{:name "Datum/Tijd",
     :width 20,
     :form (format-date-time (:datumtijd w))}
    {:name "Wedstrijd",
     :width 40,
     :form (wedstrijd-href (:id w) (:opmerkingen w))}
    {:name "Scheidsrechter",
     :width 30,
     :form
     (if
         (= "uit" (:lokatie w))
       "Uit wedstrijd"
       (persoon-href (:pid w) (:pnaam w)))}
    {:name "Status", :width 10, :form (:status w)}]})



;; TODO als je meer dan 1 actie wilt, dan past dit zo niet. Dan mss meerdere submit buttons,
;; maar waarschijnlijk meerdere forms nodig.
(def-object-form acties-form person
  {:obj-type :persoon
   :obj-part :delete
   :submit-label "Verwijder persoon"})

(def-object-page persoon
  {:base-page-fn base-page
   :page-name "Scheids"
   :parts [{:title "Algemeen" :part-fn persoon-form}
           {:title "Eigen teams" :part-fn persoon-teams-form}
           {:title "Afwezig" :part-fn persoon-afwezig-form}
           {:title "Kan teams fluiten" :part-fn kan-team-fluiten-form}
           {:title "Kost factoren" :part-fn costfactor-form}
           {:title "Wedstrijden" :part-fn scheids-wedstrijden}
           {:title "Acties" :part-fn acties-form}]
   :model-read-fn mp/persoon-by-id
   :name-fn :naam
   :debug true})

(def-view-crud :obj-type :persoon
  :redir-update-type :persoon
  :redir-delete-type :personen
  :model-ns mediaweb.models.persoon)

;; TODO wrapper macro voor deze, zodat je redir-types and model-ns maar een keer hoeft op te geven?
(def-view-crud :obj-type :afwezig
  :redir-update-type :persoon
  :redir-delete-type :persoon
  :model-ns mediaweb.models.persoon)

(def-view-crud :obj-type :kan_team_fluiten
  :redir-update-type :persoon
  :redir-delete-type :persoon
  :model-ns mediaweb.models.persoon)

(def-view-crud :obj-type :costfactor
  :redir-update-type :persoon
  :model-ns mediaweb.models.persoon)

(def-view-crud :obj-type :persoon_team
  :redir-update-type :persoon
  :redir-delete-type :persoon
  :model-ns mediaweb.models.persoon)

