(ns startingclojure.app
  (:use (compojure handler
                   [core :only (GET POST defroutes)]))
  (:require compojure.route
            [net.cgrand.enlive-html :as en] 
            [ring.util.response :as response] 
            [ring.adapter.jetty :as jetty])
  (:use clojure.pprint)) ; separate module in clojure 1.5.1

(defonce counter (atom 10000))

(defonce urls (atom {}))

(defn shorten
  [url]
  (let [id (swap! counter inc)
        id (Long/toString id 36)]
    (swap! urls assoc id url)
    id))

(en/deftemplate homepage-old 
  (en/xml-resource "homepage.html")
  [request]
  ; listing hier is case sensitive, moet in html ook zelfde zijn!
  [:#listing :li] (en/clone-for [[id url] @urls]
                                [:a] (en/content (format "%s => %s" id url))
                                [:a] (en/set-attr :href (str "/" id))))

(en/deftemplate homepage
  (en/xml-resource "homepage.html")
  [request]
  ; listing hier is case sensitive, moet in html ook zelfde zijn!
  [:#listing :li] (en/clone-for [[id url] @urls]
                     [:a] (comp
                            (en/content (format "%s <=> %s" id url))
                            (en/set-attr :href (str "/" id)))))

(defn redirect 
  [id]
  (response/redirect (@urls id)))

(defn app-old
  [request]
  {:status 200
   :body (with-out-str
           (pprint request))})

(defroutes app* 
 ; (POST "/" request (pprint request))
  (compojure.route/resources "/")
  (GET "/" request (homepage request)) ; request is hier de ring-request
  (POST "/shorten" request 
        (let [id (shorten (-> request :params :url))]
          (response/redirect "/")))
  (GET "/:id" [id] (redirect id)))

(def app (compojure.handler/site app*))

;(defn run
;  []
;  (defonce server (jetty/run-jetty #'app {:port 8080 :join? false})))

; om manual te starten vanuit REPL (on-the-fly aanpassen lukt nu ook: maar na Ctrl-S ook de code selecteren en met ctrl-enter evalueren!)
; (defonce server (jetty/run-jetty #'app {:port 8080 :join? false}))

