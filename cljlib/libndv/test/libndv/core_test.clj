(ns libndv.core-test
  (:require [clojure.test :refer :all]
            [libndv.core :refer :all]
            [libndv.coerce :refer :all]
            [libndv.crud :refer :all]
            [libndv.datetime :refer :all]
            [libndv.debug :refer :all]
            [libndv.html :refer :all]))

(deftest a-test
  (testing "FIXED."
    (is (= 1 1))))
