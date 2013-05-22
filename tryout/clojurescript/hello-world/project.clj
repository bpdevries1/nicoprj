(defproject hello-world "0.1.0-SNAPSHOT"
  :description "ClojureScript first example Hello World."
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :plugins [[lein-cljsbuild "0.3.0"]]
  :dependencies [[org.clojure/clojure "1.5.1"]
  ;               [org.clojure/clojurescript "0.0-1450"]]
                 [org.clojure/clojurescript "0.0-1586"]
                 [compojure "1.1.5"]
                 [ring/ring-jetty-adapter "1.1.1"]]
  ; :plugins [[lein-cljsbuild "0.2.7"]]
  :source-paths ["src/clj"]
  :cljsbuild {
    :builds [{
      ; :source-path "src/cljs"
      ; 9-5-2013 paths van gemaakt, ergens gelezen?
      :source-paths ["src/cljs"]
      :compiler {
        :output-to "resources/public/hello.js"
        :optimizations :whitespace
        :pretty-print true}}]})

; clojurescript version: http://mvnrepository.com/artifact/org.clojure/clojurescript
; lein-clojurescript 1.1.0

; lein-cljsbuild version: https://github.com/emezeske/lein-cljsbuild

; invoke REPL: lein trampoline cljsbuild repl-rhino
; "Type: " :cljs/quit " to quit"

; bRepl starten
; op clojure repl:
;(use 'ring.adapter.jetty)
;(use 'compojure.route)
;(run-jetty (resources "/") {:port 3000 :join? false})

; If your Ring server and bREPL server are running, you can visit 
; localhost:3000/hello.html in your browser, and upon loading, the bREPL client will establish
; a connection to the bREPL server and you can start evaluating forms. 
; ClojureScript:cljs.user> (js/alert "Hello from bREPL!")

