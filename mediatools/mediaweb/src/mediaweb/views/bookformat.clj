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

(defn bookformats
  "Dummy/placeholder because of ref in endpoint" [& rest])

(def-object-form bookformat-form bookformat
  {:obj-type :bookformat
   :actions #{:edit :delete}
   :fields [{:label "Format" :field :format :attrs {:size 10}}
            {:label "Notes" :field :notes :ftype text-area :attrs {:rows 5 :cols 80}}]})

(def-objects-form books-form bf b
  {:main-type :bookformat
   :row-type :book
   :model-read-fn mb/bookformat-books
   :actions #{},
   :columns [{:name "Title", :width 15, :form (book-href (:id b) (:title b))}
             {:name "Authors", :width 10, :form (:authors b)}
             {:name "Pub. date", :width 10, :form (:pubdate b)}
             {:name "Tags", :width 15, :form (:tags b)}
             {:name "Notes", :width 40, :form (:notes b)}]})

(def-objects-form relfiles-form bf rf
  {:main-type :bookformat
   :row-type :relfile
   :model-read-fn mb/bookformat-relfiles
   :actions #{:delete}
   :columns
   [{:name "Filename", :width 15, :form (relfile-href (:id rf) (:filename rf))}
    {:name "Rel.Folder", :width 25, :form (:relfolder rf)}
    {:name "Size", :width 5, :attrs {:align :right}
     :form (format-filesize (:filesize rf))}
    {:name "Timestamp", :width 20, :attrs {:align :center}
     :form (format-date-time (:ts rf))}
    {:name "Notes", :width 20, :form (:notes rf)}]})

(def-objects-form files-form bf f
  {:main-type :bookformat
   :row-type :file
   :model-read-fn mb/bookformat-files
   :actions #{:delete}
   :columns
   [{:name "Filename", :width 15, :form (file-href (:id f) (:filename f))}
    {:name "Folder", :width 25, :form (:folder f)}
    {:name "Size", :width 5, :attrs {:align :right}
     :form (format-filesize (:filesize f))}
    {:name "Timestamp", :width 20, :attrs {:align :center}
     :form (format-date-time (:ts f))}
    {:name "Notes", :width 20, :form (:notes f)}]})

(def-object-page bookformat
  {:base-page-fn base-page
   :page-name "Bookformat"
   :parts [{:title "General" :part-fn bookformat-form}
           {:title "Books" :part-fn books-form}
           {:title "Rel.files" :part-fn relfiles-form}
           {:title "Files" :part-fn files-form}]
   :model-read-fn mb/bookformat-by-id
   :name-fn :format
   :debug true})

(def-view-crud :obj-type :bookformat
  :redir-update-type :bookformat
  :redir-delete-type :books
  :model-ns mediaweb.models.bookformat)

