(ns functional.message-controller-test
  (:use clojure.contrib.test-is
        controllers.message-controller)
  (:require [conjure.core.controller.util :as controller-util]))

(def controller-name "message")

