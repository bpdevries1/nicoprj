(ns mediaweb.views.itemgroup
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
   [mediaweb.models.itemgroup :as mg]
   [mediaweb.views.general :refer :all]))

(def-view-crud :obj-type :itemgroup
  :redir-update-type :itemgroup
  :redir-delete-type :itemgroups
  :model-ns mediaweb.models.itemgroup)

(def-view-crud :obj-type :itemgroupquery
  :redir-update-type :itemgroup
  :redir-delete-type :itemgroup
  :model-ns mediaweb.models.itemgroup)

(def-view-crud :obj-type :member
  :redir-update-type :itemgroup
  :redir-delete-type :itemgroup
  :model-ns mediaweb.models.itemgroup)

(def-objects-form itemgroups-form itemgroups g
  {:model-read-fn (fn [_] (mg/all-itemgroups)),
   :actions #{:add-get},
   :row-type :itemgroup,
   :columns [{:name "Name", :width 15, :form (itemgroup-href (:id g) (:name g))}
             {:name "Notes", :width 10, :form (:notes g)}
             {:name "Tags", :width 15, :form (:tags g)}]})

(def-page itemgroups
  {:base-page-fn base-page
   :page-name "Groups"
   :page-fn itemgroups-form})

(def-object-form itemgroup-form itemgroup
  {:obj-type :itemgroup
   :actions #{:edit :delete}
   :fields [{:label "Name" :field :name :attrs {:size 80}}
            {:label "Notes" :field :notes :ftype text-area :attrs {:rows 5 :cols 80}}
            {:label "Tags" :field :tags :attrs {:size 40}}]})

;; idee is combi van inline edit en springen naar detail page.
;; kijken of multiline in tabel een beetje werkt.
;; kijken hoe width en size/cols samen werken.
;; TODO: main-type naam wellicht iets van column of ref.
;; TODO: row-type wordt alleen in url's gebruikt.
(def-objects-form queries-form g q
  {:main-type :itemgroup_id
   :row-type :itemgroupquery
   :model-read-fn mg/itemgroup-queries
   :columns [{:name "Name" :width 10 :form {:field :name}}
             {:name "Type" :width 5 :form {:field :type :attrs {:size 10}}}
             {:name "Query" :width 40
              :form {:field :query :ftype text-area :attrs {:rows 5 :cols 40}}}
             {:name "Notes" :width 40
              :form {:field :notes :ftype text-area :attrs {:rows 5 :cols 40}}}
             {:name "Details" :width 10 :form (itemgroupquery-href (:id q) "Details")}]})

;; TODO: items/members opnemen, hier ook main-type/row-type gebeuren.

(def-object-page itemgroup
  {:base-page-fn base-page
   :page-name "Group"
   :parts [{:title "General" :part-fn itemgroup-form}
           {:title "Queries" :part-fn queries-form}]
   :model-read-fn mg/itemgroup-by-id
   :name-fn :name
   :debug true})

;; 4 dummy functies omdat ze in endpoint macro gebruikt worden:
;; TODO: dus in def-with-default-routes kunnen zeggen dat je alleen update/delete routes wilt.
;; of 4 mogelijkheden, in een set. Of in een map, om meteen de goede namen aan te geven.
(defn itemgroupqueries [])
(defn members [])
(defn itemgroupquery [])
(defn member [])

;; TODO: itemgroupquery waarsch ook losse page, om deze te editen en later ook objecten mee
;; te beheren, of toe te voegen. Tenzij je dit doet vanuit het hoofd itemgroup scherm.


