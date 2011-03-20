(defproject scheidsclj "1.0.0-SNAPSHOT"
  :description "Referee schedule in Clojure"
  :dependencies [[org.clojure/clojure "1.2.0"]
                 [org.clojure/clojure-contrib "1.2.0"]
                 [clojureql "1.1.0-SNAPSHOT"]
                 ;[org.clojars.kjw/mysql-connector "5.1.11"]
                 ;[org.clojars.kjw/mysql-connector "5.0.4"]
                 ;[mysql/mysql-connector-java "5.1.6"]
                 [mysql/mysql-connector-java "5.0.4"]
                 [clj-time "0.3.0-SNAPSHOT"]
                 [clargon "1.0.0"]]
  :main scheidsclj.core)

; gebruik mysql connector 5.0.4 ivm problemen met id generatie en teruggeven
; Message: Generated keys not requested

;; even niet    [clojureql "1.1.0-SNAPSHOT"]] 
; [clojureql "1.0.0"]
