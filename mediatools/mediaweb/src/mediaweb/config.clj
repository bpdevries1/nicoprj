(ns mediaweb.config
  (:require [environ.core :refer [env]]))

(def defaults
  ^:displace {:http {:port 3001}})

;; TODO uri gebruiken zodat je het op Heroku neer kunt zetten?
(def environ
  {:http {:port (some-> env :port Integer.)}
   :db {:dbname   (env :dbname)
        :user     (env :dbuser)
        :password (env :dbpassword)}})

