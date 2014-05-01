(ns cljs-node2.core)

(def express (js/require "express")) ;; require express
(def sqlite3 (js/require "sqlite3")) ;; require sqlite3
(def mystr "This is my string")

;; (defn open-db [path]
;;   (def f (.-Database sqlite3))
;;   (def db (f. path))
;;   db)  

(defn open-db [path]
  (let [f (.-Database sqlite3)]
    (f. path)))

;;         (.serialize db (fn [] 
;;           (.run db "CREATE TABLE IF NOT EXISTS Stuff (thing TEXT)")
;;           (.run db "CREATE TABLE IF NOT EXISTS Stuff2 (thing TEXT)")
;;           (.run db "insert into Stuff2 values ('Tweede tekst')")))
;;         
; @todo #() constructie gebruiken => werkt niet zoals hieronder staat.
; @todo evt nog kijken welke code gegenereerd wordt, en of je hier iets mee kan.
(defn db-exec [db stmt]
  (.serialize db (fn [] (.run db stmt))))

; onderstaande lukt niet: Object #<Database> has no method 'call'
;(defn db-exec [db stmt]
;  (.serialize db #((.run db stmt))))


(defn start [& _]
  (println "Server started on port 3000")
  (def app        (express))                    ;; create the app
  (def fs           (js/require "fs"))            ;; require fs
  (def *rs* nil)
  
  ;; localhost:3000
  (.get app "/" (fn [req res]
                  (.send res "Hello world!")))
  
  ;; localhost:3000/user/andrei
  (.get app "/user/:name" (fn [req res]
                       (.send res (aget req "params" "name"))))
  
  ;; localhost:3000/read
  ;; be sure to specify a valid path to read from
  (.get app "/read"
        (fn [req res]
          (set! *rs* (.createReadStream fs "testfile.txt"))
          (.pipe *rs* res)))
  


;; // JavaScript
;; var today = new Date(2012, 6, 16);
;; ;; ClojureScript
;; (def today (js/Date. 2012 6 16))
;; 
  
  ;; sqlite db read
  (.get app "/dbread"
        (fn [req res]
          ;; var db = new sqlite3.Database(file);
          ; (def db (sqlite3.Database. "testdb.db"))
          ; (def db (sqlite3/Database. "testdb.db"))
          (def mystr2 mystr)
          ; (def f (Database. sqlite3))
          
          ; onderstaand in 2 regels, werkt:
          ;(def f (.-Database sqlite3))
          ;(def db (f. "testdb.db"))
          ; (def db ((.-Database sqlite3). "testdb.db")) -> helaas, _SLASH_ is not defined.
          ; vermoed dat x. echt syntax/reader constructie is, en dus niet dynamisch met functie aanroep kan.
          ; dan met functie
          (def db (open-db "testdb.db"))          
          
          ; db.serialize(function() {
          ;  if(!exists) {
          ;    db.run("CREATE TABLE Stuff (thing TEXT)");
          ;  }
          ;});

;;         (.serialize db (fn [] 
;;           (.run db "CREATE TABLE IF NOT EXISTS Stuff (thing TEXT)")
;;           (.run db "CREATE TABLE IF NOT EXISTS Stuff2 (thing TEXT)")
;;           (.run db "insert into Stuff2 values ('Tweede tekst')")))
;;         
          (db-exec db "CREATE TABLE IF NOT EXISTS Stuff (thing TEXT)")
          (db-exec db "CREATE TABLE IF NOT EXISTS Stuff2 (thing TEXT)")
          (db-exec db "insert into Stuff2 values ('Derde tekst')")
          
          ; db.close();
          (.close db)
          ; (.send res "Results of DB query:")))
          (.send res mystr2)))
  
  ;; what port to bind the application on
  (.listen app 3000))

;; must have a main function
(set! *main-cli-fn* start)

