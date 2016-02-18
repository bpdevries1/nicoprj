(ns mediaweb.views.general
  (:require [hiccup.form :refer [form-to text-field submit-button text-area
                                 drop-down hidden-field]]
            [hiccup.page :refer [html5 include-js include-css]]
            [libndv.core :as h]
            [libndv.html :refer [object-href]]
            #_[mediaweb.models :as models]
            #_[mediaweb.models.itemgroup :as mg]
            [mediaweb.models.entities :as ent]
            [potemkin.macros :as pm]
            [ring.util.response :as response]))

;; use https://github.com/clojure/core.typed/wiki/Types
;; for defining function params and return values.

(defn index []
  (response/redirect "/books"))

(defn base-page [title & body]
  (html5
   [:head
    (include-css "/css/bootstrap.css")
    (include-css "/css/zap.css")
    [:title title]]
   [:body
    [:div {:class "navbar navbar-inverse"}
     [:div {:class :navbar-inner}
      [:a {:class :brand :href "/authors"} "Authors"]
      [:a {:class :brand :href "/books"} "Books"]
      [:a {:class :brand :href "/directories"} "Directories"]
      [:a {:class :brand :href "/files"} "Files"]
      [:a {:class :brand :href "/itemgroups"} "Groups"]
      [:a {:class :brand :href "/actions"} "Actions"]
      [:a {:class :brand :href "/admin"} "Admin"]
      (form-to
       {:class :form-horizontal}
       [:post "/search"]
       (text-field :query)
       (submit-button {:class "btn btn-primary"} "Search"))]]
    [:div.container (seq body)]]))

(def action-href (partial object-href "action"))
(def author-href (partial object-href "author"))
(def book-href (partial object-href "book"))
(def bookformat-href (partial object-href "bookformat"))
(def directory-href (partial object-href "directory"))
(def file-href (partial object-href "file"))
(def relfile-href (partial object-href "relfile"))
(def itemgroup-href (partial object-href "itemgroup"))
(def itemgroupquery-href (partial object-href "itemgroupquery"))

(defn format-filesize
  "Format file size with thousand separators"
  [s]
  (format "%,d" s))

;; TODO: split in page and table-results parts, for selecting items.
(defn search-page
  "Search generic, all kinds of objects"
  [{:keys [query] :as params}]
  (base-page
   "Search results"
   [:h1 (str "Search results [" query "]")]
   (if-let [res (ent/search-items query)]
     [:table.table
      [:thead
       [:tr
        [:th {:width "85%"} "Item"]
        [:th {:width "15%"} "Table"]]]
      [:tbody
       (for [{:keys [item_table id title]} res]
         [:tr
          [:td (object-href item_table id title)]
          [:td item_table]])]]
     "Nothing found")))
