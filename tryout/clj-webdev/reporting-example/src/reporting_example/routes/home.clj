(ns reporting-example.routes.home
  (:require [compojure.core :refer :all]
            [reporting-example.views.layout :as layout]
            [hiccup.element :refer [link-to]]
            [ring.util.response :as response]
            [reporting-example.reports :as reports]))

(defn home []
  (layout/common
   [:h1 "Select a report:"]
   [:ul
    [:li (link-to "/list" "List report")]
    [:li (link-to "/table" "Table report")]]))

(defn write-response [report-bytes]
  (with-open [in (java.io.ByteArrayInputStream. report-bytes)]
    (-> (response/response in)
        (response/header "Content-Disposition" "filename=document.pdf")
        (response/header "Content-Length" (count report-bytes))
        (response/content-type "application/pdf"))))

(defn generate-report [report-type]
  (try
    (let [out (new java.io.ByteArrayOutputStream)]
      (condp = (keyword report-type)
        :table (reports/table-report out)
        :list  (reports/list-report out))
      (write-response (.toByteArray out)))
    (catch Exception ex
      {:status 500
       :headers {"Content/type" "text/html"}
       :body (layout/common
              [:h2 "An error has occured while generating the report"]
              [:p (.getMessage ex)])})))



(defroutes home-routes
  (GET "/" [] (home))
  (GET "/:report-type" [report-type] (generate-report report-type)))
; GET "/list" [] (reports/list-report)
