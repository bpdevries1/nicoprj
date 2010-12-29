(ns unit.model.message-model-test
  (:use clojure.contrib.test-is
        models.message
        fixture.message))

(def model "message")

(use-fixtures :once fixture)

(deftest test-first-record
  (is (get-record 1)))