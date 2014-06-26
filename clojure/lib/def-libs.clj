; Load default clojure libraries for use in (single) Clojure script file.

; @todo make namespace

(use '[leiningen.exec :only  (deps)])
(deps '[[me.raynes/fs "1.4.5"]                ; file system utilities
        [org.clojure/tools.cli "0.2.4"]
        [swiss-arrows "1.0.0"]
        [org.clojure/tools.logging "0.3.0"]
        [org.slf4j/slf4j-log4j12 "1.7.5"]     ; coupling tools.logging with log4j.
        [log4j/log4j "1.2.16"]                ; in test-log4.clj deze niet, kan het kwaad?
        [clj-logging-config "1.9.10"]
        [clj-time "0.6.0"]]) 

; use newest jdbc by defailt, has incompatbile changes from 0.2.3 to 0.3.0.
(deps '[[org.clojure/java.jdbc "0.3.3"]
        [org.xerial/sqlite-jdbc "3.7.2"]]) ; 3.7.2 lijkt nog wel de nieuwste ([2014-05-03 22:39:14])

(require '[clojure.java.io :as io] 
         '[clojure.string :as str]
         '[me.raynes.fs :as fs]
         '[clojure.java.jdbc :as jdbc]
         '[clojure.tools.cli :refer [cli]]
         '[swiss.arrows :refer :all]            ; bij deze refer all wel handig, met -<> operators, wil hier geen namespace voor.
         '[clojure.tools.logging :as log]
         '[clj-logging-config.log4j :as logcfg]
         '[clj-time.core :as t]
         '[clj-time.format :as tf])

; 11-05-2014 for now define some extra functions, later put in (ndv?) lib.

; see http://rosettacode.org/wiki/Hostname#Clojure 
(defn computername
  "Get computername, works both on windows and linux"
  []
  (.. java.net.InetAddress getLocalHost getHostName))

; SQLite database related:
(def db-spec-sqlite {:classname "org.sqlite.JDBC"
                     :subprotocol "sqlite"})

(defn db-spec-path
  "Create db-spec based on template and path"
  [db-spec db-path]
  (assoc db-spec :subname (fs/expand-home db-path)))

(defn missing-required?
  "Returns true if opts is missing any of the required-opts"
  [opts required-opts]
  (not-every? opts required-opts))

(defn my-cli
  "Wrapper around cli function in clojure.tools.cli. Return nil if not parsed correctly, also print banner then"
  [args required-opts & specs]
  (try 
    (let [[opts args banner] (apply cli (rest args) specs)]
      (if (or (:help opts)
              (missing-required? opts required-opts))
        (println banner) ; also returns nil
        opts))  
    (catch java.lang.Exception e 
      (do (println (.getMessage e)) 
          (println specs))))) ; also returns nil
  
(defmacro pr-syms
  "Print a sequence of symbol names with their values"
  [& symbols]
  `(do ~@(map (fn [s] `(println '~s "=" ~s)) symbols))) 

(defmacro log-exprs
  "Log a sequence of expressions with their values"
  [& exprs]
  `(do ~@(map (fn [s] `(log/debug (str '~s "=" ~s))) exprs))) 

; 3 functions for finding files recursively without following symbolic links.
; @todo one main function, the others with letfn or defn-
(defn file-seq-nolink
  "A tree seq on java.io.Files without following symlinks"
  {:added "1.0"
   :static true}
  [dir]
    (tree-seq
     (fn [^java.io.File f] (and (. f (isDirectory)) (not (fs/link? f)))) 
     (fn [^java.io.File d] (seq (. d (listFiles))))
     dir))

(defn find-files-nolink*
  "Find files in path by pred."
  [path pred]
  (filter pred (-> path fs/file file-seq-nolink)))

(defn find-files-nolink
  "Find files matching given pattern."
  [path pattern]
  (find-files-nolink* path #(re-matches pattern (.getName %))))

; logging functions
(defn logfile-name
  "Determine logfile based on script file name"
  [script-name]
  (let [dt (tf/unparse (tf/formatter "yyyy-MM-dd--hh-mm-ss" (t/default-time-zone)) (t/now))]
    (str (fs/file (fs/parent script-name) (str (fs/name script-name) "-" dt ".log")))))

; @todo maybe some options to have a logfile, always same name or not.
(defn set-log4j!
  "Set log4j logging for the script"
  [& args]
  (let [argsmap (merge {:level :info} (apply hash-map args))]
    (logcfg/set-loggers! 
      (str *ns*) {:name "console" :level (:level argsmap) :pattern "[%d{HH:mm:ss,SSS}] [%-5p] %m%n"}
      (str *ns*) {:name "file" :level (:level argsmap) :pattern "[%d] [%-5p] %m%n" 
                  :out (logfile-name (first *command-line-args*))})))

(defn file-lines
  "Read lines from files; ignore empty lines and lines starting with #"
  [path]
  (-<> (slurp path)
       (str/split <> #"\r?\n")
       (filter #(not (re-find #"^#" %)) <>)   ; ignore lines starting with #
       (filter #(not (re-find #"^$" %)) <>))) ; ignore empty lines

