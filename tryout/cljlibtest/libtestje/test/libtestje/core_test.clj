(ns libtestje.core-test
  (:require [clojure.test :refer :all]
            [libtestje.core :refer :all]))

(deftest answer-test
  (testing "Answer = 42"
    (is (= 42 (give-answer)))))

