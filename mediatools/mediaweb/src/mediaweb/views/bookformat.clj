(ns mediaweb.views.bookformat
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
   [mediaweb.models.bookformat :as mb]
   [mediaweb.views.general :refer :all]))

#_(def-page books
  {:base-page-fn base-page
   :page-name "Books"
   :page-fn books-form})

(defn bookformats
  "Dummy/placeholder because of ref in endpoint" [& rest])

(def-object-form bookformat-form bookformat
  {:obj-type :bookformat
   :actions #{:edit :delete}
   :fields [{:label "Format" :field :format :attrs {:size 10}}
            {:label "Notes" :field :notes :ftype text-area :attrs {:rows 5 :cols 80}}]})

(def-object-page bookformat
  {:base-page-fn base-page
   :page-name "Bookformat"
   :parts [{:title "General" :part-fn bookformat-form}]
   :model-read-fn mb/bookformat-by-id
   :name-fn :format
   :debug true})

(def-view-crud :obj-type :bookformat
  :redir-update-type :bookformat
  :redir-delete-type :books
  :model-ns mediaweb.models.bookformat)

