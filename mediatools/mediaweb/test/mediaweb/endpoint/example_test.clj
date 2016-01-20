(ns mediaweb.endpoint.example-test
  (:require [com.stuartsierra.component :as component]
            [clojure.test :refer :all]
            [kerodon.core :refer :all]
            [kerodon.test :refer :all]
            ;;[mediaweb.endpoint.example :as example]
            ))

#_(def handler
  (example/example-endpoint {}))

#_(deftest smoke-test
  (testing "index page exists"
    (-> (session handler)
        (visit "/")
        (has (status? 200) "page exists"))))
