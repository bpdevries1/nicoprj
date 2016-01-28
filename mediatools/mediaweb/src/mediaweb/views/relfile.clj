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

(def-object-page relfile
  {:base-page-fn base-page
   :page-name "Relfile"
   :parts [{:title "General" :part-fn relfile-form}]
   :model-read-fn mr/relfile-by-id
   :name-fn :filename
   :debug true})

(def-view-crud :obj-type :relfile
  :redir-update-type :relfile
  :redir-delete-type :files
  :model-ns mediaweb.models.relfile)

