(ns picture-gallery.handler
  (:require [compojure.core :refer [defroutes]]
            [compojure.route :as route]
            [noir.util.middleware :as noir-middleware]
            [picture-gallery.routes.home :refer [home-routes]]
            [picture-gallery.routes.auth :refer [auth-routes]]
            [picture-gallery.routes.upload :refer [upload-routes]]
            [picture-gallery.routes.gallery :refer [gallery-routes]]
            [noir.session :as session]
            [taoensso.timbre :as timbre]
            [com.postspectacular.rotor :as rotor]))

(defn info-appender [{:keys [level message]}]
  (println "level:" level "message:" message))

(defn init []
  ; (println "picture-gallery is starting")
  (timbre/set-config! [:timestamp-pattern] "yyyy-MM-dd HH:mm:ss")
  (timbre/set-config! [:appenders :rotor]
     {:min-level :info
      :enabled? true
      :async? false ; should always be false for rotor
      :max-message-per-msecs nil
      :fn rotor/append})

  (timbre/set-config!
   [:shared-appender-config :rotor]
   {:path "/var/log/picture-gallery-error.log" :max-size (* 512 1024) :backlog 10})
  
  (timbre/info "picture-gallery started successfully"))

(defn destroy []
  (timbre/info "picture-gallery is shutting down"))

; _ param is request map
(defn user-page [_]
  (session/get :user))

(defroutes app-routes
  (route/resources "/")
  (route/not-found "Not Found"))

#_(def app
  (-> (routes home-routes app-routes)
      (handler/site)
      (wrap-base-url)))

(def app (noir-middleware/app-handler
          [auth-routes
           home-routes
           upload-routes
           gallery-routes
           app-routes]
          :access-rules [user-page]))
