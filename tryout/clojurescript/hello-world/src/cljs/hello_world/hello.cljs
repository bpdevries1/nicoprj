;(ns hello-world.hello)
;(.write js/document "<p>Hello, Nico!</p>")

(ns hello-world.hello
  (:require [clojure.browser.repl :as repl]))
(repl/connect "http://localhost:9000/repl")

