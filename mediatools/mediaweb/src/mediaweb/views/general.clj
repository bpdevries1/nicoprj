(ns mediaweb.views.general
  (:require [hiccup.page :refer [html5 include-js include-css]]
            [hiccup.form :refer [form-to text-field submit-button text-area
                                 drop-down hidden-field]]
            [ring.util.response :as response]
            [mediaweb.models :as models]
            [potemkin.macros :as pm]
            [libndv.core :as h]
            [libndv.html :refer [object-href]]))

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

;; TODO remove these 3 after other code (from scheids) does not use it anymore.
(def persoon-href (partial object-href "persoon"))
(def team-href (partial object-href "team"))
(def wedstrijd-href (partial object-href "wedstrijd"))

(defn format-filesize
  "Format file size with thousand separators"
  [s]
  (format "%,d" s))

