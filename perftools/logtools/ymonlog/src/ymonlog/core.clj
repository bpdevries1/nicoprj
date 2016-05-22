(ns ymonlog.core
  (:gen-class)
  ; refer-clojure verwijderd uit core, wel opnemen in ddl.clj en dml.clj.
  ;(:refer-clojure :exclude [take drop sort distinct compile conj! disj! case]) ; 31-12-2011 deze constructie in SocialSite gezien (Lau Jensen), ook case erbij gezet.
  ;(:refer-clojure :exclude [bigint boolean char double float time])           ; deze voor Lobos, nu even niet.
  ; removed clojureql.core, now in dml.clj.
  (:use [clj-time.core :exclude (extend)]    ; moeten de haakjes om extend geen [] zijn?
        clj-time.format                      ; nu niet nodig, om datum/tijd berekeningen te doen: dt + offset, verschil tussen 2.
        clj-time.coerce                      ; nu niet nodig, om van/naar bv tcl seconds te vertalen.
        [clojure.java.io :only [reader]]
        ymonlog.ddl
        ymonlog.dml))
;        lobos.connectivity  ; 8-1-12 remove for now, name clashes with clojureQL. maybe better to create db in a separate namespace with separate use's.
;        lobos.core
;        lobos.schema))
; (use '[clojure.java.io :only (reader)])

(def db
{:classname "org.sqlite.JDBC"
:subprotocol "sqlite"
:subname "/tmp/cql.sqlite3"
:create true})

;(use 'clojureql.core) 

;(open-global db)

; (use '[clojure.java.io :only (reader)])
; 07:32:15 09/20/2011	Exclusive monitor timed out waiting to start: QTP_MSTAD
; tab tussen tijd en msg, in RE door . vervangen.
(defn read-error-log
  "Read ymonitor error.log file"
  [filename]
  (with-open [rdr (reader filename)]
    (doseq [line (line-seq rdr)]
      ; (println line) ; boel wordt wel gelezen, want geprint.
      (when-let [[_ tm month day year monitor] (re-find #"^([^ ]+) ([0-9]{2})/([0-9]{2})/([0-9]{4}).Exclusive monitor timed out waiting to start: (.+)$" line)]
        (println "Found: " year month day tm "Monitor: " monitor)
        (insert-db-event 
          (zipmap [:ts :type :monitor :logtext] 
                  [(format "%s-%s-%s %s" year month day tm) "excl-timeout" monitor line])))))) 

; @todo this function is similar in structure to read-error-log, make general function? Use of .split is different.
; split in tabs results in following.
; 00:34:13 01/03/2012
; good
; 382
; QTP_EZIS_VDI
; Sentinel: WKS00879,Script: MSZ_28122011_NDV_V01_EZIS_VDI,DateTime: 03/01/2012 00:29:08,,Transaction: 01_Start_VMWare ( D: 13.6331 sec. / S: Pass ), Transaction: 02_VDI_Connect ( D: 33.1678 sec. / S: Pass ), Transaction: 03_EZIS_Start ( D: 33.5721 sec. / S: Pass ), Transaction: 04_EZIS_Inloggen ( D: 105.7768 sec. / S: Pass ), Transaction: 05_EZIS_Werkblad ( D: 12.677 sec. / S: Pass ), Transaction: 06_EZIS_PatientZoeken ( D: 3.5082 sec. / S: Pass ), Transaction: 07_EZIS_Zoeken ( D: 7.7595 sec. / S: Pass ), Transaction: 08_PACS_Start ( D: 14.5023 sec. / S: Pass ), Transaction: 09_PACS_Close ( D: 3.4935 sec. / S: Pass ), Transaction: 10_EZIS_Reset ( D: 4.7696 sec. / S: Pass ), Transaction: 11_EZIS_Close ( D: 6.725 sec. / S: Pass ), Transaction: 12_VDI_Close ( D: 5.9535 sec. / S: Pass ), ,Total duration: 245.53844 sec.,Transactions: 12 / 12,Warnings: 0,Errors: 0,,Script id: 2065,
; 1:308
; 0
; @todo can the two when-let's be combined?
(defn read-sitescope-log
  "Read Sitescope-<date>.log file"
  [filename]
  (with-open [rdr (reader filename)]
    (doseq [line (line-seq rdr)]
      (when-let [[ts-e status _ monitor text] (seq (.split line "\t"))]
        (when-let [[_ day-s month-s year-s tm-s] (re-find #"DateTime: ([0-9]{2})/([0-9]{2})/([0-9]{4}) ([0-9:]+)" text)]
          (let [[_ tm-e month-e day-e year-e] (re-find #"^([^ ]+) ([0-9]{2})/([0-9]{2})/([0-9]{4})" ts-e)]
            (println "Found: " line)
            (insert-db-interval
              (zipmap [:ts_start :ts_end :type :monitor :status :logtext]
                      [(format  "%s-%s-%s %s" year-s month-s day-s tm-s)
                       (format  "%s-%s-%s %s" year-e month-e day-e tm-e)
                       "scriptrun" monitor status line]))))))))


; http://corfield.org/blog/post.cfm/real-world-clojure-powermta-log-files
(defn wildcard-filter
  "Given a regex, return a FilenameFilter that matches."
  [re]
  (reify java.io.FilenameFilter
    (accept [_ dir name] (not (nil? (re-find re name))))))

;http://corfield.org/blog/post.cfm/real-world-clojure-powermta-log-files
(defn directory-list
  "Given a directory and a regex, return a sorted seq of matching filenames."
  [dir re]
  (sort (.list (clojure.java.io/file dir) (wildcard-filter re))))

(defn read-logs
  "Read ymonitor logs from folder and put them in sqlite db"
  [folder]
  (read-error-log (str folder "/" (first (directory-list folder #"^error\.log$"))))
  (doseq [filename (directory-list folder #"^SiteScope[0-9_]+\.log$")]
    (read-sitescope-log (str folder "/" filename))))
  

(defn -main [& args]
  (let [filename (first args)
        db {:classname "org.sqlite.JDBC"
            :subprotocol "sqlite"
            :subname filename 
            :create true}]
    (create-log-db db)
    (open-db db)
    (println "YmonLog: main")
    ;(read-error-log "/home/nico/perftoolset/tools/ymonlog/test/error.log")
    ;(read-sitescope-log "/home/nico/perftoolset/tools/ymonlog/test/SiteScope2012_01_03.log")
    (read-logs "/home/nico/perftoolset/tools/ymonlog/test")
    (close-db)
    (println "YmonLog: finished")))



