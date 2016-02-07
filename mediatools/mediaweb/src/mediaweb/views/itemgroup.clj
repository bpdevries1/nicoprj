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

(def-object-page itemgroup
  {:base-page-fn base-page
   :page-name "Group"
   :parts [{:title "General" :part-fn itemgroup-form}]
   :model-read-fn mg/itemgroup-by-id
   :name-fn :name
   :debug true})

;; TODO: itemgroupquery waarsch ook losse page, om deze te editen en later ook objecten mee
;; te beheren, of toe te voegen. Tenzij je dit doet vanuit het hoofd itemgroup scherm.


