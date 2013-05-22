(defproject one "1.0.0-SNAPSHOT"
  :description "Getting Started with ClojureScript."
  :dependencies [[org.clojure/clojure "1.4.0"]
                 [ring "1.0.0-RC1"]
                 [compojure "0.6.4"]
                 [enlive "1.0.0"]
                 [domina "1.0.1-SNAPSHOT"]
                 [org.mozilla/rhino "1.7R3"]
                 [com.google.javascript/closure-compiler "r1592"]
                 [org.clojure/google-closure-library "0.0-790"]
                 [org.clojure/clojurescript "0.0-1450"]]
  :dev-dependencies [[jline "0.9.94"]
                     [marginalia "0.7.0-SNAPSHOT"]
                     [lein-marginalia "0.7.0-SNAPSHOT"]]
  :repl-options {:init-ns one.sample.repl}
  :source-paths ["src/clj"
                 "src/cljs"
                 "src/app/clj"
                 "src/app/cljs"
                 "src/app/shared"
                 "src/app/cljs-macros"
                 "src/lib/clj"
                 "src/lib/cljs"]
  :resource-paths ["templates"]
  :aliases {"dumbrepl" ["trampoline" "run" "-m" "clojure.main/main"]})
