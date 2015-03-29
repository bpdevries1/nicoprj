(defproject zap "0.1.0-SNAPSHOT"
  :description "Zap bug tracker"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.5.1"]
                 [ring/ring-core "1.1.8"]
                 [compojure "1.1.5"]
                 [korma "0.3.0-RC2"]
                 [org.xerial/sqlite-jdbc "3.7.2"]
                 [hiccup "1.0.2"]]
  :plugins [[lein-ring "0.8.3"]]
  :ring {:handler zap.core/app})

