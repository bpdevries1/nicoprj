(ns mediaweb.views.author
  (:require
   [hiccup.page :refer [html5 include-js include-css]]
   [hiccup.form :refer [form-to text-field submit-button text-area
                        drop-down hidden-field]]
   [ring.util.response :as response]
   [mediaweb.models :as models]
   [libndv.core :as h]
   [potemkin.macros :as pm]
   [libndv.crud :refer [def-view-crud]]
   [libndv.datetime :refer [format-date-time parse-date-time]]
   [libndv.html :refer [def-object-form def-object-page def-page 
                                    def-objects-form]]
   [mediaweb.models.author :as ma]
   [mediaweb.views.general :refer :all]))

;; TODO: goede velden.
(def-objects-form authors-form authors a
  {:model-read-fn (fn [_] (ma/all-authors)),
   :actions #{:add-get},
   :row-type :author,
   :columns [{:name "Full name", :width 40,
              :form (author-href (:id a) (:fullname a))}
             {:name "Notes", :width 40, :form (:notes a)}]})

(def-page authors
  {:base-page-fn base-page
   :page-name "Authors"
   :page-fn authors-form})

;; TODO: goede velden.
(def-object-form author-form author
  {:obj-type :author
   :fields [{:label "Full name" :field :fullname :attrs {:size 40}}
            {:label "First name" :field :firstname :attrs {:size 20}}
            {:label "Last name" :field :lastname :attrs {:size 20}}
            {:label "Notes" :field :notes :ftype text-area :attrs {:rows 5 :cols 80}}]})

;; TODO als je meer dan 1 actie wilt, dan past dit zo niet. Dan mss meerdere submit buttons,
;; maar waarschijnlijk meerdere forms nodig.
(def-object-form author-actions-form author
  {:obj-type :author
   :obj-part :delete
   :submit-label "Delete author"})

(def-object-page author
  {:base-page-fn base-page
   :page-name "Author"
   :parts [{:title "General" :part-fn author-form}
           {:title "Actions" :part-fn author-actions-form}]
   :model-read-fn ma/author-by-id
   :name-fn :fullname
   :debug true})

;; parse-date-time aanroepen als pre-fn.
(def-view-crud :obj-type :author
  :redir-update-type :author
  :redir-delete-type :authors
  :model-ns mediaweb.models.author)

