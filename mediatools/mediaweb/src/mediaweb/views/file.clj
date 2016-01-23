(ns mediaweb.views.file
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
   [mediaweb.models.file :as mf]
   [mediaweb.views.general :refer :all]))

;; TODO file-add functionaliteit maken, had ik nog helemaal niet.
(def-objects-form files-form files f
  {:model-read-fn (fn [_] (mf/all-files)),
   :actions #{:add-get},
   :row-type :file,
   :columns [{:name "Filename", :width 15, :form (file-href (:id f) (:filename f))}
             {:name "Folder", :width 25, :form (:folder f)}
             {:name "Size", :width 5, :attrs {:align :right}
              :form (format "%,d" (:filesize f))}
             {:name "Timestamp", :width 20, :attrs {:align :center}
              :form (format-date-time (:ts f))}
             {:name "Notes", :width 20, :form (:notes f)}]})

(def-page files
  {:base-page-fn base-page
   :page-name "Files"
   :page-fn files-form})

;; TODO: str file straks weer voor andere objecten erbij gejoined.
(def-object-form directory-form file
  {:actions #{}
   :obj-type :file
   :fields [(directory-href (:dir_id file) (:dir_fullpath file))
            #_(str file)]})

(def-object-form file-form file
  {:obj-type :file
   :fields [{:label "Filename" :field :filename :attrs {:size 80}}
            {:label "Filesize" :field :filesize :attrs {:size 10 :readonly true}}
            {:label "Timestamp" :field :ts :format-fn format-date-time
             :attrs {:readonly true}}
            {:label "MD5" :field :md5 :attrs {:size 32 :readonly true}}
            {:label "Goal" :field :goal}
            {:label "Importance" :field :importance}
            {:label "Computer" :field :computer :attrs {:readonly true}}
            {:label "Srcbak" :field :srcbak}
            {:label "Notes" :field :notes :ftype text-area :attrs {:rows 5 :cols 80}}]})

(def-objects-form file-actions-form f a
  {:model-read-fn mf/file-actions
   ;; TODO: add-get verziekt form, kijken waarom, fout in macro?
   ;; TODO: actie kunnen toevoegen: dan alleen type veld vullen, mss dropdown lijst? Nog wel vraag wanneer/waarom je dit wilt.
   ;; TODO: deze def bijna gelijk aan die van het hoofd-actions-scherm. Komt dit vaker voor, wil je 'em dan hergebruiken, clonen. Want model-read-fn is wel net anders.
   ;;   :actions #{:add-get},
   :actions #{} ;;; vooralsnog geen acties, read only.
   :row-type :action,
   :columns [{:name "Create ts", :width 20,
              :form (action-href (:id a) (format-date-time (:create_ts a)))}
             {:name "Action", :width 10, :form (:action a)}
             {:name "Exec ts", :width 20,
              :form (format-date-time (:exec_ts a))}
             {:name "Status" :width 10 :form (:exec_status a)}
             {:name "Notes", :width 40, :form (:notes a)}]})

;; TODO: als je meer dan 1 actie wilt, dan past dit zo niet. Dan mss meerdere submit buttons,
;; maar waarschijnlijk meerdere forms nodig.
;; TODO: bij deze delete actie mogelijk ook uit het file systeem verwijderen.
;; TODO: obj-part mogelijk hernoemen naar :action
(def-object-form gui-actions-form file
  {:obj-type :file
   :obj-part :delete
   :submit-label "Delete file"})

(def-object-page file
  {:base-page-fn base-page
   :page-name "File"
   :parts [{:title "Directory" :part-fn directory-form}
           {:title "General" :part-fn file-form}
           {:title "File actions" :part-fn file-actions-form}
           {:title "Actions" :part-fn gui-actions-form}]
   :model-read-fn mf/file-by-id
   :name-fn :filename
   :debug true})

(def-view-crud :obj-type :file
  :redir-update-type :file
  :redir-delete-type :files
  :model-ns mediaweb.models.file)

