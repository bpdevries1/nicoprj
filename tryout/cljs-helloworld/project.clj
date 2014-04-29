(defproject cljs-helloworld "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :cljsbuild {
              :builds [{
                        :source-path "src"
                        :compiler {
                                   :target :nodejs
                                   :optimizations :advanced
                                   :pretty-print true}}]}
  :dependencies [[org.clojure/clojure "1.5.1"]])

