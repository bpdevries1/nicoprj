(defproject mediaweb "0.1.0-SNAPSHOT"
  :description "Scheids web interface"
  :url "http://example.com/FIXME"
  :min-lein-version "2.0.0"
  :dependencies [[org.clojure/clojure "1.7.0"]
                 [com.stuartsierra/component "0.3.0"]
                 [compojure "1.4.0"]
                 [duct "0.4.4"]
                 [environ "1.0.1"]
                 [meta-merge "0.1.1"]
                 [ring "1.4.0"]
                 [ring/ring-defaults "0.1.5"]
                 [ring-jetty-component "0.3.0"]
                 ;; [korma "0.3.0-RC2"]
                 [korma "0.4.2"]
                 [postgresql "9.3-1102.jdbc41"]
                 [hiccup "1.0.2"]
                 [potemkin "0.4.1"]
                 [clj-time "0.8.0"]
                 
                 ;; the ones below from batch/lein-exec
                 [me.raynes/fs "1.4.5"]                ; file system utilities
                 [org.clojure/tools.cli "0.2.4"]
                 [swiss-arrows "1.0.0"]
                 [org.clojure/tools.logging "0.3.0"]
                 [org.slf4j/slf4j-log4j12 "1.7.5"]     ; coupling tools.logging with log4j.
                 [log4j/log4j "1.2.16"]                ; in test-log4.clj deze niet, kan het kwaad?
                 [clj-logging-config "1.9.10"]
                 ;;[org.clojure/java.jdbc "0.3.3"]
                 [org.clojure/java.jdbc "0.4.2"]

                 ;; and my own NdV library.
                 [vreeze42/libndv "0.1.0-SNAPSHOT"]]
  :plugins [[lein-environ "1.0.1"]
            [lein-gen "0.2.2"]]
  :generators [[duct/generators "0.4.4"]]
  :duct {:ns-prefix mediaweb}
  :main ^:skip-aot mediaweb.main
  :target-path "target/%s/"
  :aliases {"gen"   ["generate"]
            "setup" ["do" ["generate" "locals"]]}
  ;; de :ring keyword staat er met duct niet meer in.
  ;;  :ring {:handler mediaweb.core/app}
  :profiles
  {:dev  [:project/dev  :profiles/dev]
   :test [:project/test :profiles/test]
   :uberjar {:aot :all}
   :profiles/dev  {}
   :profiles/test {}
   :project/dev   {:source-paths ["dev"]
                   :repl-options {:init-ns user}
                   :dependencies [[reloaded.repl "0.2.0"]
                                  [org.clojure/tools.namespace "0.2.11"]
                                  [eftest "0.1.0"]
                                  [kerodon "0.7.0"]]
                   ;; 29-12-2015 even op 3002 ipv 3000 gezet, wordt deze gelezen? Ja
                   ;; take 2: port3 ipv port zetten -> port is nil en server start niet.
                   ;; take 3: hele env weg -> port is weer nil, weer niet gestart.
                   :env {:port 3001}}
   :project/test  {}})
