(defproject vreeze42/libndv "0.1.0-SNAPSHOT"
  :description "Library functions mostly for server side web apps"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :min-lein-version "2.0.0"
  ;; TODO cleanup dependencies.
  :dependencies [[org.clojure/clojure "1.7.0"]
                 ;; TODO ones above are needed, ones below need to check.
                 [com.stuartsierra/component "0.3.0"]
                 [compojure "1.4.0"]
                 [duct "0.4.4"]
                 [environ "1.0.1"]
                 [meta-merge "0.1.1"]
                 [ring "1.4.0"]
                 [ring/ring-defaults "0.1.5"]
                 [ring-jetty-component "0.3.0"]
                 [korma "0.3.0-RC2"]
                 [postgresql "9.3-1102.jdbc41"]
                 [hiccup "1.0.2"]
                 [potemkin "0.4.1"]
                 [clj-time "0.8.0"]])
