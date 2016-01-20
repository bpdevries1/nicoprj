(ns mediaweb.views
  (:require [hiccup.page :refer [html5 include-js include-css]]
            [hiccup.form :refer [form-to text-field submit-button text-area
                                 drop-down hidden-field]]
            [ring.util.response :as response]
            [mediaweb.models :as models]
            [potemkin.macros :as pm]))

(defn admin [])

