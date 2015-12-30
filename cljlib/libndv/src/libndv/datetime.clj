(ns libndv.datetime
  (:require [clj-time.core :as t]
            [clj-time.coerce :as tc]
            [clj-time.format :as tf]
          ;;  [potemkin.macros :as pm]
          ;;  [hiccup.page :refer [html5 include-js include-css]]
          
          ;;  [hiccup.form :refer [form-to text-field submit-button text-area                                  drop-down hidden-field]]
         ;;   [ring.util.response :as response]
            ))

(def fmtr-wd-date-tz
  (tf/with-zone
    (tf/formatter "EEE dd-MM-yyyy")
    (t/default-time-zone)))

(def fmtr-date-tz
  (tf/with-zone
    (tf/formatter "dd-MM-yyyy")
    (t/default-time-zone)))

(def fmtr-basicdate-tz
  (tf/with-zone
    (tf/formatter "yyyyMMdd")
    (t/default-time-zone)))

(def fmtr-time-tz
  (tf/with-zone
    (tf/formatter "HH:mm")
    (t/default-time-zone)))

(def fmtr-wd-date-time-tz
  (tf/with-zone
    (tf/formatter "EEE dd-MM-yyyy HH:mm")
    (t/default-time-zone)))

(def fmtr-date-time-tz
  (tf/with-zone
    (tf/formatter "dd-MM-yyyy HH:mm")
    (t/default-time-zone)))

;; string 20141231
(defn as-date-string [sqldatetime]
  ;;(tf/unparse (tf/formatters :basic-date) (tc/to-date-time sqldatetime))
  (tf/unparse fmtr-basicdate-tz (tc/to-date-time sqldatetime)))

;; string "EEE dd-MM-yyyy"
(defn format-date [sqldatetime]
  (tf/unparse fmtr-date-tz (tc/to-date-time sqldatetime)))

;; string "dd-MM-yyyy"
(defn format-wd-date [sqldatetime]
  (tf/unparse fmtr-wd-date-tz (tc/to-date-time sqldatetime)))

;; string "HH:mm"
(defn format-time [sqldatetime]
  (tf/unparse fmtr-time-tz (tc/to-date-time sqldatetime)))

;; string "EEE dd-MM-yyyy HH:mm"
(defn format-wd-date-time [sqldatetime]
  (tf/unparse fmtr-wd-date-time-tz (tc/to-date-time sqldatetime)))

(defn format-date-time
  "return string dd-MM-yyyy HH:mm" 
  [sqldatetime]
  (tf/unparse fmtr-date-time-tz (tc/to-date-time sqldatetime)))

;; #inst "dd-MM-yyyy HH:mm"
(defn parse-date-time [datetime]
  (tf/parse fmtr-date-time-tz datetime))

;; #inst "dd-MM-yyyy"
;; new date as typed by the user could be empty, eg with 'afwezig'/absent end-date.
(defn parse-date [date]
  (if (pos? (count date))
    (tf/parse fmtr-date-tz date)))

;; TODO Met date functies doen, maar dan wel afwezig als tijdstippen noteren, dus inclusief
;; tijd. Dat enkele dag afwezig dus is: begin is dag 0:00 en eind is dag 23:59.
(defn date-between
  "returns true iff d is between d-start and d-end, inclusive"
  [d d-start d-end]
  (let [ds (as-date-string d)]
    (and (>= (compare ds (as-date-string d-start)) 0)
         (<= (compare ds (as-date-string d-end)) 0))))
