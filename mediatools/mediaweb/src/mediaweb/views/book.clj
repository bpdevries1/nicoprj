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
   :columns [{:name "Title", :width 15, :form (book-href (:id b) (:title b))}
             {:name "Authors", :width 10, :form (:authors b)}
             {:name "Pub. date", :width 10, :form (:pubdate b)}
             {:name "Tags", :width 15, :form (:tags b)}
             {:name "Notes", :width 40, :form (:notes b)}]})

(def-page books
  {:base-page-fn base-page
   :page-name "Books"
   :page-fn books-form})

(def-object-form book-form book
  {:obj-type :book
   :actions #{:edit :delete}
   :fields [{:label "Title" :field :title :attrs {:size 80}}
            {:label "Authors" :field :authors :attrs {:size 80}}
            {:label "Language" :field :language}
            {:label "Edition" :field :edition}
            {:label "#Pages" :field :npages :attrs {:size 5}}
            {:label "Publication date" :field :pubdate}
            {:label "Publisher" :field :publisher}
            {:label "ISBN 10" :field :isbn10 :attrs {:size 11}}
            {:label "ISBN 13" :field :isbn13 :attrs {:size 14}}
            {:label "Tags" :field :tags :attrs {:size 40}}
            {:label "Notes" :field :notes :ftype text-area :attrs {:rows 5 :cols 80}}]})

(def-objects-form formats-form b bf
  {:main-type :book
   :row-type :bookformat
   :model-read-fn mb/book-formats
   :actions #{}
   :columns
   [{:name "Format" :width 30 :form (bookformat-href (:id bf) (:format bf))}
    {:name "Notes"  :width 50 :form (:notes bf)}]})

(def-objects-form relfiles-form b rf
  {:main-type :book
   :row-type :relfile
   :model-read-fn mb/book-relfiles
   :actions #{:delete}
   :columns
   [{:name "Filename", :width 15, :form (relfile-href (:id rf) (:filename rf))}
    {:name "Rel.Folder", :width 25, :form (:relfolder rf)}
    {:name "Size", :width 5, :attrs {:align :right}
     :form (format-filesize (:filesize rf))}
    {:name "Timestamp", :width 20, :attrs {:align :center}
     :form (format-date-time (:ts rf))}
    {:name "Notes", :width 20, :form (:notes rf)}]})

(def-objects-form files-form b f
  {:main-type :book
   :row-type :file
   :model-read-fn mb/book-files
   :actions #{:delete}
   :columns
   [{:name "Filename", :width 15, :form (file-href (:id f) (:filename f))}
    {:name "Folder", :width 25, :form (:folder f)}
    {:name "Size", :width 5, :attrs {:align :right}
     :form (format-filesize (:filesize f))}
    {:name "Timestamp", :width 20, :attrs {:align :center}
     :form (format-date-time (:ts f))}
    {:name "Notes", :width 20, :form (:notes f)}]})

;; TODO: mss Files hoger neerzetten?
(def-object-page book
  {:base-page-fn base-page
   :page-name "Book"
   :parts [{:title "General" :part-fn book-form}
           {:title "Formats" :part-fn formats-form}
           {:title "Rel.files" :part-fn relfiles-form}
           {:title "Files" :part-fn files-form}]
   :model-read-fn mb/book-by-id
   :name-fn :title
   :debug true})

(def-view-crud :obj-type :book
  :redir-update-type :book
  :redir-delete-type :books
  :model-ns mediaweb.models.book)

