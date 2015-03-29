(defproject hello "0.1.0-SNAPSHOT"
  :description "Hello World"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.5.1"]
                 [ring/ring-core "1.1.8"]
                 [compojure "1.1.5"]]
  :plugins [[lein-ring "0.8.3"]]
  :ring {:handler hello.core/app})

