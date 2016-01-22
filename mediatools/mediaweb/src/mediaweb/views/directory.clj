(ns mediaweb.views.directory
  (:require
   [hiccup.page :refer [html5 include-js include-css]]
   [hiccup.form :refer [form-to text-field submit-button text-area
                        drop-down hidden-field]]
   [ring.util.response :as response]
   [mediaweb.models :as models]
   [potemkin.macros :as pm]
   [me.raynes.fs :as fs]
   [libndv.core :as h]
   [libndv.crud :refer [def-view-crud]]
   [libndv.datetime :refer [format-date-time parse-date-time]]
   [libndv.html :refer [def-object-form def-object-page def-page 
                        def-objects-form]]
   
   [mediaweb.models.directory :as md]
   [mediaweb.views.general :refer :all]))

;; TODO: goede velden.
(def-objects-form directories-form directories d
  {:model-read-fn (fn [_] (md/all-directories)),
   :actions #{:add-get},
   :row-type :directory,
   :columns [{:name "Full path" :width 80 :form (directory-href (:id d) (:fullpath d))}
             {:name "Computer" :width 20 :form (:computer d)}]})

(def-page directories
  {:base-page-fn base-page
   :page-name "Directories"
   :page-fn directories-form})

;; TODO: goede velden.
(def-object-form directory-form directory
  {:obj-type :directory
   :fields [{:label "Fullpath" :field :fullpath :attrs {:size 80}}
            {:label "Computer" :field :computer :attrs {:size 20}}]})

(def-object-form parent-form d
  {:actions #{}
   :obj-type :directory
   :fields [(directory-href (:parent_id d) (:parent_fullpath d))]})

(def-objects-form subdirs-form dir subdir
  {:main-type :directory
   :row-type :directory
   :model-read-fn md/subdirs
   :actions #{}
   ;; TODO: maybe replace fullpath with just the last part, actual name
   :columns [{:width 100 :name "Name" :form (directory-href (:id subdir) (fs/base-name (:fullpath subdir)))}]})

(def-objects-form files-form dir f
  {:main-type :directory
   :row-type :file
   :model-read-fn md/files
   :actions #{}
   :columns [{:name "Name" :width 55 :form (file-href (:id f) (:filename f))}
             {:name "Size", :width 5, :attrs {:align :right}
              :form (format "%,d" (:filesize f))}
             {:name "Timestamp", :width 20, :attrs {:align :center}
              :form (format-date-time (:ts f))}
             {:name "Notes", :width 20, :form (:notes f)}]})

;; TODO als je meer dan 1 actie wilt, dan past dit zo niet. Dan mss meerdere submit buttons,
;; maar waarschijnlijk meerdere forms nodig.
(def-object-form directory-actions-form directory
  {:obj-type :directory
   :obj-part :delete
   :submit-label "Delete directory"})

(def-object-page directory
  {:base-page-fn base-page
   :page-name "Directory"
   :parts [{:title "General" :part-fn directory-form}
           {:title "Parent" :part-fn parent-form}
           {:title "Subdirs" :part-fn subdirs-form}
           {:title "Files" :part-fn files-form}
           {:title "Actions" :part-fn directory-actions-form}]
   :model-read-fn md/directory-by-id
   :name-fn :fullpath
   :debug true})

;; parse-date-time aanroepen als pre-fn.
(def-view-crud :obj-type :directory
  :redir-update-type :directory
  :redir-delete-type :directories
  :model-ns mediaweb.models.directory
  
;;  :pre-fn #(assoc % :ts_cet (parse-date-time (:ts_cet %)))
  )

