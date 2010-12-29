(ns views.home.index
  (:use conjure.core.view.base))

; niet meer nodig
(defn
  message-displayed? [id]
  (= (conjure.core.server.request/id) (str id)))

; niet meer nodig
(defn
  message-text []
  (str "Message " (conjure.core.server.request/id)))

; niet meer nodig
(defn
  message-link [id]
  (list
    (button-to message-text { :params { :id id } })
    " "))

(def-view [message messages]
  [:div { :class "article" }
    [:h1 "Welcome to Conjure!"]
    [:p#message (hiccup.core/h (:text message))]
    (ajax-form-for
  { :update (success-fn "message" :replace)
    :action :ajax-message
    :html-options { :action (conjure.core.view.util/url-for { :controller :home, :action :index }) } }
  [:p "Enter the id of the message to display:" 
    (select-tag message :record :id { :options (map :id messages) } )
    (form-button "Submit")])])


