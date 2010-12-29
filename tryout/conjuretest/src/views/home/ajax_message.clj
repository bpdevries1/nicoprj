(ns views.home.ajax-message
  (:use conjure.core.view.base))

(def-ajax-view [message]
  [:p#message (hiccup.core/h (:text message))])
