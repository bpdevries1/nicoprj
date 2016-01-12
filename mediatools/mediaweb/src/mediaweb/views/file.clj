(ns mediaweb.views.file
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
   [mediaweb.models.file :as mf]
   [mediaweb.views.general :refer :all]))

;; TODO file-add functionaliteit maken, had ik nog helemaal niet.
(def-objects-form files-form files f
  {:model-read-fn (fn [_] (mf/all-files)),
   :actions #{:add-get},
   :row-type :file,
   :columns [{:name "Filename", :width 15, :form (file-href (:id f) (:filename f))}
             {:name "Folder", :width 25, :form (:folder f)}
             {:name "Size", :width 5, :form (:filesize f)}
             {:name "Timestamp", :width 10, :form (:ts f)}
             {:name "Notes", :width 20, :form (:notes f)}]})

(def-page files
  {:base-page-fn base-page
   :page-name "Files"
   :page-fn files-form})

(def-object-form file-form file
  {:obj-type :file
   :fields [{:label "Filename" :field :filename :attrs {:size 40}}
            {:label "Folder" :field :folder :attrs {:size 80}}
            {:label "Fullpath" :field :fullpath :attrs {:size 80}}
            {:label "Filesize" :field :filesize :attrs {:size 10}}
            {:label "Timestamp" :field :ts}
            {:label "Timestamp CET" :field :ts_cet}
            {:label "MD5" :field :md5 :attrs {:size 32}}
            {:label "Directory ID" :field :directory_id}
            {:label "RelFile ID" :field :relfile_id}
            {:label "Goal" :field :goal}
            {:label "Importance" :field :importance}
            {:label "Computer" :field :computer}
            {:label "Srcbak" :field :srcbak}
            {:label "Notes" :field :notes :ftype text-area :attrs {:rows 5 :cols 80}}]})

;; TODO: als je meer dan 1 actie wilt, dan past dit zo niet. Dan mss meerdere submit buttons,
;; maar waarschijnlijk meerdere forms nodig.
;; TODO: bij deze delete actie mogelijk ook uit het file systeem verwijderen.
;; TODO: obj-part mogelijk hernoemen naar :action
(def-object-form actions-form file
  {:obj-type :file
   :obj-part :delete
   :submit-label "Delete file"})

(def-object-page file
  {:base-page-fn base-page
   :page-name "File"
   :parts [{:title "General" :part-fn file-form}
           {:title "Actions" :part-fn actions-form}]
   :model-read-fn mf/file-by-id
   :name-fn :filename
   :debug true})

(def-view-crud :obj-type :file
  :redir-update-type :file
  :redir-delete-type :files
  :model-ns mediaweb.models.file)

