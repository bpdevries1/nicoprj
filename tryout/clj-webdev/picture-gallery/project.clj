(defproject picture-gallery "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :dependencies [[org.clojure/clojure "1.6.0"]
                 [compojure "1.1.6"]
                 [hiccup "1.0.5"]
                 [ring-server "0.3.1"]
                 [postgresql/postgresql "9.1-901.jdbc4"]
                 ; jdbc not needed, Korma takes care of this. But do this later.
;                 [org.clojure/java.jdbc "0.2.3"]
                 [lib-noir "0.8.2"]
                 [com.taoensso/timbre "2.6.1"]
                 [com.postspectacular/rotor "0.1.0"]
                 [environ "0.4.0"]
                 [http-kit "2.1.12"]
                 [korma "0.3.0-RC5"]
                 [log4j "1.2.15"
                  :exclusions [javax.mail/mail
                               javax.jms/jms
                               com.sun.jdmk/jmxtools
                               com.sun.jmx/jmxri]]]
  :plugins [[lein-ring "0.8.10"]
            [lein-environ "0.4.0"]]
  :ring {:handler picture-gallery.handler/app
         :init picture-gallery.handler/init
         :destroy picture-gallery.handler/destroy}
  :aot :all
  :main picture-gallery.main
  :profiles
  {:production
   {:ring
    {:open-browser? false,
     :stacktraces? false,
     :auto-reload? false}
    :env {:port 3000
          :db-url "//localhost/gallery"
          :db-user "admin"
          :db-pass "admin"
          :galleries-path "galleries"}}
   :dev
   {:dependencies [[ring-mock "0.1.5"]
                   [ring/ring-devel "1.2.1"]]
    :env {:port 3000
          :db-url "//localhost/gallery"
          :db-user "admin"
          :db-pass "admin"
          :galleries-path "galleries"}}})

