(ns mediaweb.views.wedstrijd
  (:require
   [hiccup.page :refer [html5 include-js include-css]]
   [hiccup.form :refer [form-to text-field submit-button text-area
                        drop-down hidden-field]]
   [ring.util.response :as response]
   [mediaweb.models :as models]
   [libndv.core :as h]
   [libndv.crud :refer [def-view-crud]]
   [libndv.datetime :refer [as-date-string format-date-time format-time
                                        format-wd-date parse-date-time]]
   [libndv.html :refer [def-object-form def-object-page def-objects-form]]
   [mediaweb.models.persoon :as mp]
   [mediaweb.models.wedstrijd :as mw]
   [mediaweb.views.general :refer :all]))

(def-objects-form wedstrijden-datum-table ws w
  {:model-read-fn identity,
   :actions {},
   :columns [{:name "Tijd" :width 10 :form (format-time (:datumtijd w))}
             {:name "Wedstrijd" :width 40 :form (wedstrijd-href (:id w) (:opmerkingen w))}
             {:name "Scheidsrechter" :width 30 :form (persoon-href (:pid w) (:pnaam w))}
             {:name "Status" :width 10 :form (:status w)}]})

;; beetje een hack om een map met id veld mee te geven.
(defn wedstrijden-datum [ws]
  (seq [[:h2 (format-wd-date (:datumtijd (first ws)))]
        (wedstrijden-datum-table {:id ws})]))

;; 2015-11-07 this one is a special, for now no macro for this situation.
(defn wedstrijden []
  (base-page
   "Thuis-wedstrijden - Scheids"
   [:div.row.admin-bar
    [:a {:href "/wedstrijden/new"}
     "Add Wedstrijd"]]       ; kan handig zijn voor beker wedstrijden.
   [:h1 "Thuis-wedstrijden"]
   (let [ws (mw/thuis-wedstrijden)
         ;; as-date-string needed for correct ordering and grouping.
         wsg (group-by (comp as-date-string :datumtijd) ws)
         wdates (sort (keys wsg))]
     (for [wd wdates]
       (wedstrijden-datum (get wsg wd))))))

;; notes-form to place in wedstrijd details view. Option to change notes.
;; wel vraag wat je met deze wint tov van de normale functie def.
;; vooral meer consistency in naamgeving en mss ook wel default rows/span8 voor textfields.
(def-object-form notes-form wedstrijd
  {:obj-type :wedstrijd
   :obj-part :notes
   :fields [{:label "Notes" :field :notes
             :ftype text-area :attrs {:rows 5 :class "span8"}}]
   :submit-label "Pas notities aan"})

(def-object-form datum-tijd-form wedstrijd
  {:obj-type :wedstrijd :obj-part :datumtijd
   :submit-label "Pas datum/tijd aan"
   :fields [{:label "dd-mm-yyyy HH:MM" :field :datumtijd
             :format-fn format-date-time}
            {:label "Notities bij aanpassing" :field :notes
             :ftype text-area :attrs {:rows 2 :class "span8"}}]})

(def-object-form scheids-change-form wedstrijd
  {:obj-type :wedstrijd :obj-part :scheids
   :submit-label "Pas scheids aan"
   :fields [(drop-down :persoon
                       (concat [["" "0"]]
                               (map (juxt :naam :id) (mp/all-personen)))
                       (:pid wedstrijd))
            {:ftype text-area :field :notes
             :label "Notities bij scheids aanpassing"
             :attrs {:rows 2 :class "span8"}}]})

(def-objects-form wedstrijd-wijzigingen w h
  {:model-read-fn mw/scheids-history-by-wedstrijd
   :actions {}
   :columns [{:name "Datum" :width 20 :form (format-date-time (:date_changed h))}
             {:name "Notes" :width 30 :form (:opmerkingen h)}
             {:name "Scheids oud" :width 30 :form (persoon-href (:pid-old h) (:pnaam-old h))}
             {:name "Scheids nieuw" :width 30 :form (persoon-href (:pid-new h) (:pnaam-new h))}]})

;; TODO in eerste instantie per wedstrijd en scheids bepalen, later mogelijk queries samenvoegen.
(def-objects-form alternatives-list w p
  {:model-read-fn (fn [_]
                    (remove
                     (fn [p#] (= "Invaller" (:naam p#)))
                     (mp/all-personen))),
   :actions {}
   :columns [{:name "Scheids" :width 30 :form (persoon-href (:id p) (:naam p))}
             {:name "Notes" :width 50 :form (mw/wedstrijd-persoon-notes w p)}]})

(def-object-page wedstrijd
  {:base-page-fn base-page
   :page-name "Wedstrijd"
   :parts [{:title "Datum/tijd" :part-fn datum-tijd-form}
           {:title "Scheidsrechter" :part-fn scheids-change-form}
           {:title "Notities" :part-fn notes-form}
           {:title "Wijzigingen" :part-fn wedstrijd-wijzigingen}
           {:title "Alternatieven" :part-fn alternatives-list}]
   :model-read-fn mw/wedstrijd-by-id
   :name-fn :opmerkingen
   :debug true})

(defn wedstrijd-notes-update [id params]
  (mw/wedstrijd-notes-update id (:notes params) (:status params))
  (response/redirect-after-post (str "/wedstrijd/" id)))

;; TODO deze nog eens gebruiken ipv 3 losse functies nu. Maar nu te specifiek, niet heel handig
;; om standaard crud macros hiervoor te gebruiken.
#_(def-view-crud :obj-type :wedstrijd
  :redir-update-type :wedstrijd
  :redir-delete-type :wedstrijden
  :model-ns mediaweb.models.wedstrijd)

(defn wedstrijd-datumtijd-update [id params]
  (mw/wedstrijd-datumtijd-update
   id (parse-date-time (:datumtijd params)) (:notes params))
  (response/redirect-after-post (str "/wedstrijd/" id)))

(defn wedstrijd-scheids-update [id params]
  (if (not= "0" (:persoon params))
    (mw/wedstrijd-scheids-update id (:persoon params) (:notes params)))
  (response/redirect-after-post (str "/wedstrijd/" id)))

;; een route/functie voor de drie bovenstaande functies:
;; even de vraag of deze beter is, want kortere functies lijken beter, en deze hierboven mss
;; beter nameless/anonymous te maken, of met macro.
;; redirect nu wel maar 1x.
;; met deze evt een hidden form-field te maken met form-id erin. Dan hierop branchen.
;; iets met referer zou ook moeten kunnen, dat je altijd naar dezelfde page terugkeert, iig als
;; default.
(defn wedstrijd-update [id params]
  (cond
    (:datumtijd params) (mw/wedstrijd-datumtijd-update
                         id (parse-date-time (:datumtijd params)) (:notes params))
    (:persoon params) (if (not= "0" (:persoon params))
                        (mw/wedstrijd-scheids-update id (:persoon params) (:notes params)))
    :else (mw/wedstrijd-notes-update id (:notes params) (:status params)))
  (response/redirect-after-post (str "/wedstrijd/" id)))

