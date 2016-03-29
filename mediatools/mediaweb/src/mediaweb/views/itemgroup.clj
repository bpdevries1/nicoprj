(ns mediaweb.views.itemgroup
  (:require
   [hiccup.page :refer [html5 include-js include-css]]
   [hiccup.form :refer [form-to text-field submit-button text-area
                        drop-down hidden-field check-box]]
   [ring.util.response :as response]
   [potemkin.macros :as pm]

   [libndv.core :as h]
   [libndv.coerce :refer [to-int to-key]]
   [libndv.crud :refer [def-view-crud]]
   [libndv.datetime :refer [format-date-time]]
   [libndv.html :refer [def-object-form def-object-page def-page 
                        def-objects-form object-href]]
   
   [mediaweb.models :as models]
   [mediaweb.models.itemgroup :as mg]
   [mediaweb.models.entities :as ent]
   [mediaweb.views.general :refer :all]))

(def-view-crud :obj-type :itemgroup
  :redir-update-type :itemgroup
  :redir-delete-type :itemgroups
  :model-ns mediaweb.models.itemgroup)

(def-view-crud :obj-type :itemgroupquery
  :redir-update-type :itemgroup
  :redir-update-key :itemgroup_id
  :redir-delete-type :itemgroup
  :redir-delete-key :itemgroup_id
  :model-ns mediaweb.models.itemgroup)

(def-view-crud :obj-type :member
  :redir-update-type :itemgroup
  :redir-update-key :itemgroup_id
  :redir-delete-type :itemgroup
  :redir-delete-key :itemgroup_id
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

(def-objects-form members-form g m
  {:main-type :itemgroup
   :main-key :itemgroup_id
   :row-type :member
   :actions #{:delete}
   :model-read-fn mg/itemgroup-members
   :columns [{:name "Title" :width 60 :form (object-href
                                             (:item_table m) (:item_id m)
                                             (:title m))}
             {:name "Item type" :width 5 :form (:item_table m)}
             {:name "Member type" :width 5 :form (:type m)}]})

#_(def-object-form query-add-form itemgroup
  {:obj-type :itemgroup
   :actions #{:search} ;; kijken of dit werkt.
   :fields [{:label "Query" :field :query :attrs {:size 80}}]})

(defn members-add-url
  "Just a URL to a next page to add members"
  [itemgroup params]
  [:a {:href (str "/itemgroup-add/" (:id itemgroup))} "Add new members"]
  #_(str "itemgroup: " itemgroup))

(def-object-form itemgroup-form itemgroup
  {:obj-type :itemgroup
   :actions #{:edit :delete}
   :fields [{:label "Name" :field :name :attrs {:size 80}}
            {:label "Notes" :field :notes :ftype text-area :attrs {:rows 5 :cols 80}}
            {:label "Tags" :field :tags :attrs {:size 40}}]})

;; idee is combi van inline edit en springen naar detail page.
;; kijken of multiline in tabel een beetje werkt.
;; kijken hoe width en size/cols samen werken.
(def-objects-form queries-form g q
  {:main-type :itemgroup
   :main-key :itemgroup_id
   :row-type :itemgroupquery
   :model-read-fn mg/itemgroup-queries
   :columns [{:name "Name" :width 10 :form {:field :name}}
             {:name "Type" :width 5 :form {:field :type :attrs {:size 10}}}
             {:name "Query" :width 40
              :form {:field :query :ftype text-area :attrs {:rows 5 :cols 40}}}
             {:name "Notes" :width 40
              :form {:field :notes :ftype text-area :attrs {:rows 5 :cols 40}}}
             {:name "Details" :width 10 :form (itemgroupquery-href (:id q) "Details")}]})

(def-object-page itemgroup
  {:base-page-fn base-page
   :page-name "Group"
   :parts [{:title "Members" :part-fn members-form}
           {:title "Add members" :part-fn members-add-url}
           {:title "General" :part-fn itemgroup-form}
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

(defn itemgroup-add-search-form
  "Search form for adding itemgroup members"
  [ig params]
  (form-to
   {:class :form-horizontal}
   [:post (str "/itemgroup-add/" (:id ig))]
   (text-field {:size 60} :query (:query params))
   (submit-button {:class "btn btn-primary"} "Search")))

(defn itemgroup-add-items-form
  "Search results for adding itemgroup members"
  [ig params]
  (if (:query params)
    (if-let [res (seq (ent/search-items (:query params)))]
      (form-to
       {:class :form-horizontal}
       [:post (str "/itemgroup-add-members/" (:id ig))]
       [:table.table
        [:thead
         [:tr
          [:th {:width "5%"} "Check"]
          [:th {:width "85%"} "Item"]
          [:th {:width "15%"} "Table"]]]
        [:tbody
         (for [{:keys [item_table id title]} res]
           [:tr
            [:td (check-box (str item_table ":" id))]
            [:td (object-href item_table id title)]
            [:td item_table]])]]
       (submit-button {:class "btn btn-primary"} "Add selected"))
      "Nothing found")
    "Type a query"))

;; 28-3-2016 spul hieronder om items aan group toe te voegen.
;; TODO: bij toevoegen checken of item al niet een member is?
;; TODO: dit integreren met main itemgroup page/form.
(defn itemgroup-add
  "Show page to add members to a group, including results of searching items."
  [id params]
  (let [ig (mg/itemgroup-by-id id)]
    (base-page "Add members to group"
               [:div.row.admin-bar]
               ;; TODO: add link back to itemgroup, possibly H1.
               [:h1 (itemgroup-href id (:name ig))]
               [:table.table
                [:tbody
                 [:tr
                  [:th.span1 "Current items"]
                  [:td.span10 (members-form ig params)]]
                 [:tr
                  [:th.span1 "Search"]
                  [:td.span10 (itemgroup-add-search-form ig params)]]
                 [:tr
                  [:th.span1 "Found items"]
                  [:td.span10 (itemgroup-add-items-form ig params)]]]])))

;; id: 1, params: {"book:53" "true", "file:173" "true"}
(defn itemgroup-add-members
  [id params]
  #_(println (str "id: " id ", params: " params))
  (doseq [item (keys params)]
    (do
      #_(println (str "item: " item))
      (let [[_ item-table item-id] (first (re-seq #"^([^:]+):(\d+)$" item))]
        (println(str item-table " => " item-id))
        (mg/member-insert {:itemgroup_id id
                           :type "manual"
                           :item_table item-table
                           :item_id (to-key item-id)}))))
  (response/redirect-after-post (str "/itemgroup-add/" id))
  #_(str "id: " id ", params: " params))

;; TODO: itemgroupquery waarsch ook losse page, om deze te editen en later ook objecten mee
;; te beheren, of toe te voegen. Tenzij je dit doet vanuit het hoofd itemgroup scherm.
