(ns mediaweb.views.relfile
  (:require
   [hiccup.page :refer [html5 include-js include-css]]
   [hiccup.form :refer [form-to text-field submit-button text-area
                        drop-down hidden-field]]
   [ring.util.response :as response]
   [potemkin.macros :as pm]
   
   [libndv.core :as h]
   [libndv.crud :refer [def-view-crud]]
   [libndv.datetime :refer [format-date-time]]
   [libndv.html :refer [def-object-form def-object-page def-page 
                                    def-objects-form]]
   [mediaweb.models :as models]
   [mediaweb.models.relfile :as mr]
   [mediaweb.views.general :refer :all]))

(defn relfiles
  "Dummy for endpoint def."
  [& rest])

(def-object-form relfile-form relfile
  {:obj-type :relfile
   :actions #{:edit :delete}
   :fields [{:label "Filename" :field :filename :attrs {:size 80}}
            {:label "Rel.folder" :field :relfolder :attrs {:size 80}}
            {:label "Filesize" :field :filesize :format-fn format-filesize
             :attrs {:size 10 :readonly true}}
            {:label "Timestamp" :field :ts :format-fn format-date-time
             :attrs {:readonly true}}
            {:label "MD5" :field :md5 :attrs {:size 32 :readonly true}}
            {:label "Notes" :field :notes :ftype text-area :attrs {:rows 5 :cols 80}}]})

(def-objects-form books-form rf b
  {:main-type :relfile
   :row-type :book
   :model-read-fn mr/relfile-books
   :actions #{},
   :columns [{:name "Title", :width 15, :form (book-href (:bid b) (:title b))}
             {:name "Authors", :width 10, :form (:authors b)}
             {:name "Pub. date", :width 10, :form (:pubdate b)}
             {:name "Tags", :width 15, :form (:tags b)}
             {:name "Notes", :width 40, :form (:notes b)}]})

(def-objects-form bookformats-form rf bf
  {:main-type :relfile
   :row-type :bookformat
   :model-read-fn mr/relfile-bookformats
   :actions #{}
   :columns
   [{:name "Format" :width 30 :form (bookformat-href (:bfid bf) (:format bf))}
    {:name "Notes"  :width 50 :form (:notes bf)}]})

(def-objects-form files-form rf f
  {:main-type :relfile
   :row-type :file
   :model-read-fn mr/relfile-files
   :actions #{:delete}
   :columns
   [{:name "Filename", :width 15, :form (file-href (:id f) (:filename f))}
    {:name "Folder", :width 25, :form (:folder f)}
    {:name "Size", :width 5, :attrs {:align :right}
     :form (format-filesize (:filesize f))}
    {:name "Timestamp", :width 20, :attrs {:align :center}
     :form (format-date-time (:ts f))}
    {:name "Notes", :width 20, :form (:notes f)}]})

(def-object-page relfile
  {:base-page-fn base-page
   :page-name "Relfile"
   :parts [{:title "General" :part-fn relfile-form}
           {:title "Books" :part-fn books-form}
           {:title "Formats" :part-fn bookformats-form}
           {:title "Files" :part-fn files-form}]
   :model-read-fn mr/relfile-by-id
   :name-fn :filename
   :debug true})

(def-view-crud :obj-type :relfile
  :redir-update-type :relfile
  :redir-delete-type :files
  :model-ns mediaweb.models.relfile)

