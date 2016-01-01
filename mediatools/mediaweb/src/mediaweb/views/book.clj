(ns mediaweb.views.book
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
   [mediaweb.models.book :as mb]
   [mediaweb.views.general :refer :all]))

(def-objects-form books-form books b
  {:model-read-fn (fn [_] (mb/all-books)),
   :actions #{:add-get},
   :row-type :book,
   :columns [{:name "Title", :width 10, :form (book-href (:id b) (:title b))}
             {:name "Authors", :width 10, :form (:authors b)}
             {:name "Pub. date", :width 10, :form (:pubdate b)}
             {:name "Tags", :width 10, :form (:tags b)}
             {:name "Notes", :width 80, :form (:notes b)}]})

(def-page books
  {:base-page-fn base-page
   :page-name "Books"
   :page-fn books-form})

(def-object-form book-form book
  {:obj-type :book
   :fields [{:label "Title" :field :title}
            {:label "Authors" :field :authors}
            {:label "Language" :field :language}
            {:label "Edition" :field :edition}
            {:label "#Pages" :field :npages}
            {:label "Publication date" :field :pubdate}
            {:label "Publisher" :field :publisher}
            {:label "ISBN 10" :field :isbn10}
            {:label "ISBN 13" :field :isbn13}
            {:label "Tags" :field :tags}
            {:label "Notes" :field :notes}]})

;; TODO als je meer dan 1 actie wilt, dan past dit zo niet. Dan mss meerdere submit buttons,
;; maar waarschijnlijk meerdere forms nodig.
(def-object-form actions-form book
  {:obj-type :book
   :obj-part :delete
   :submit-label "Delete book"})

(def-object-page book
  {:base-page-fn base-page
   :page-name "Book"
   :parts [{:title "General" :part-fn book-form}
           {:title "Actions" :part-fn actions-form}]
   :model-read-fn mb/book-by-id
   :name-fn :title
   :debug true})

(def-view-crud :obj-type :book
  :redir-update-type :book
  :redir-delete-type :books
  :model-ns mediaweb.models.book)

