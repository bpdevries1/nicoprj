(ns mediaweb.views.action
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
   [mediaweb.models.action :as ma]
   [mediaweb.views.general :refer :all]))

(def-objects-form actions-form actions a
  {:model-read-fn (fn [_] (ma/all-actions)),
   :actions #{:add-get},
   :row-type :action,
   :columns [{:name "Create ts", :width 20,
              :form (action-href (:id a) (format-date-time (:create_ts a)))}
             {:name "Action", :width 10, :form (:action a)}
             {:name "Full path", :width 30, :form (:fullpath_action a)}
             {:name "Exec ts", :width 20,
              :form (format-date-time (:exec_ts a))}
             {:name "Status" :width 10 :form (:exec_status a)}
             {:name "Notes", :width 40, :form (:notes a)}]})

(def-page actions
  {:base-page-fn base-page
   :page-name "Actions"
   :page-fn actions-form})

(def-object-form action-form action
  {:obj-type :action
   :fields [{:label "Create ts" :field :create_ts :format-fn format-date-time :attrs {:size 20}}
            {:label "Action" :field :action :attrs {:size 15}}
            {:label "Full path" :field :fullpath_action :attrs {:size 60}}
            (file-href (:file_id action) "go to file")
            {:label "Other path" :field :fullpath_other :attrs {:size 60}}
            {:label "Exec ts" :field :exec_ts :format-fn format-date-time :attrs {:size 20}}
            {:label "Status" :field :exec_status :attrs {:size 10}}
            {:label "Output" :field :exec_output :ftype text-area :attrs {:rows 5 :cols 80}}
            {:label "Stderr" :field :exec_stderr :ftype text-area :attrs {:rows 5 :cols 80}}
            {:label "Notes" :field :notes :ftype text-area :attrs {:rows 5 :cols 80}}]})

;; TODO als je meer dan 1 actie wilt, dan past dit zo niet. Dan mss meerdere submit buttons,
;; maar waarschijnlijk meerdere forms nodig.
(def-object-form action-actions-form action
  {:obj-type :action
   :obj-part :delete
   :submit-label "Delete action"})

(def-object-page action
  {:base-page-fn base-page
   :page-name "Action"
   :parts [{:title "General" :part-fn action-form}
           {:title "Actions" :part-fn action-actions-form}]
   :model-read-fn ma/action-by-id
   :name-fn (comp format-date-time :ts_cet)
   :debug true})

;; parse-date-time aanroepen als pre-fn.
(def-view-crud :obj-type :action
  :redir-update-type :action
  :redir-delete-type :actions
  :model-ns mediaweb.models.action
  
;;  :pre-fn #(assoc % :ts_cet (parse-date-time (:ts_cet %)))
  )

