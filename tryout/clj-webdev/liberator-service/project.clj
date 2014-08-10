(defproject liberator-service "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :dependencies [[org.clojure/clojure "1.6.0"]
                 ; [compojure "1.1.6"]
                 ; volgens http://forums.pragprog.com/forums/308/topics/12552
                 ; tools.reader versions zijn veschillend in LT en Compojure.
                 [compojure "1.1.6" :exclusions [org.clojure/tools.reader]]
                 [org.clojure/tools.reader "0.7.10"]
                 [hiccup "1.0.5"]
                 [ring-server "0.3.1"]
                 [liberator "0.11.0"]
                 [cheshire "5.3.1"]]
  :plugins [[lein-ring "0.8.10"]]
  :ring {:handler liberator-service.handler/app
         :init liberator-service.handler/init
         :destroy liberator-service.handler/destroy}
  :aot :all
  :profiles
  {:production
   {:ring
    {:open-browser? false, :stacktraces? false, :auto-reload? false}}
   :dev
   {:dependencies [[ring-mock "0.1.5"] [ring/ring-devel "1.2.1"]]}})
