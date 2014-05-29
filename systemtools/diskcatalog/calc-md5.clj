#!/bin/bash lein-exec

; calc-md5.clj

(load-file "../../clojure/lib/def-libs.clj")

(deps '[[digest "1.4.4"]])
(require 'digest)

; c:\bieb\ICT-books\(eBook - comp) Introduction To Evolutionary Computing - A.eiben,j.smith (2003).djvu
; => /media/laptop/bieb/ICT-books/(eBook - comp) Introduction To Evolutionary Computing - A.eiben,j.smith (2003).djvu
(defn to-linux-path 
  "Convert laptop/windows path like c:\\bieb to /media/laptop/bieb"
  [path]
  (if-let [[_ part] (re-find #"^c:\\(.+)$" path)] 
    (str "/media/laptop/" (clojure.string/replace part "\\" "/"))
    path))

; (clojure.string/replace "c:\\bieb\\ICT-books\\(eBook - comp) Introduction To Evolutionary Computing - A.eiben,j.smith (2003).djvu" "\\" "/")
; (to-linux-path "c:\\bieb\\ICT-books\\(eBook - comp) Introduction To Evolutionary Computing - A.eiben,j.smith (2003).djvu")

; deze functie wel aardig, maar onnodig nu, door Exception beter te bekijken.
; (det-file-status "/media/laptop/aaa") -> "exists-ok"
; (det-file-status "/media/laptop/hiberfil.sys") -> "filesys-exc-locked?"
; (det-file-status "/media/laptop/hiberfil121.sys") -> "no-such-file"
; (det-file-status "/home/nico/.teapot/%2fopt%2fActiveTcl-8.6.linux-glibc2.13-x86_64/indexcache/teapot.activestate.com/INDEX") -> "exists-ok"
(defn det-file-status
  "Determine if file is indeed not found or maybe locked/unavailable.
   Standard fs/exists? or java functions don't work as advertised. Use java.nio as
   a workaround"
  [^String path]
  (try
    ; use into-array to generate a java String array so Paths/get will use the String(s) variant instead of URI variant.
    (java.nio.file.Files/size (java.nio.file.Paths/get path (into-array String [])))
    "exists-ok"
    (catch java.nio.file.NoSuchFileException e "no-such-file")
    (catch java.nio.file.AccessDeniedException e "access-denied")
    (catch java.nio.file.FileSystemException e "filesys-exc-locked?") 
    (catch java.io.IOException e "io-exception2")))

; deze nu dus ook onnodig.
(defn file-md5-old2
  "Calculate MD5 sum for path"
  [path]
  (let [linux-path (to-linux-path path)]
    (try 
      (digest/md5 (fs/file linux-path))
      (catch java.io.FileNotFoundException e (det-file-status linux-path))
      (catch java.io.IOException e "io-exception1"))))

; @todo delete path from exception message. Only keep everything between parens.
(defn file-md5
  "Calculate MD5 sum for path"
  [^String path]
  (let [linux-path (to-linux-path path)]
    (try 
      (digest/md5 (fs/file linux-path))
      (catch java.io.IOException e (.getMessage e)))))


; @todo log in ander format, maar niet triviaal.
(defn calc-md5!
  "Calculate MD5 sum for files where md5 field is null"
  [db-spec]
  (doseq [row (jdbc/query db-spec "select id, fullpath from file where md5 is null")]
    (log/info "Calculating MD5 sum for: " (:fullpath row))
    (jdbc/execute! db-spec ["update file set md5 = ? where id = ?" (file-md5 (:fullpath row)) (:id row)])))

(defn main [args]
  (when-let [opts (my-cli args #{:database}
        ["-h" "--help" "Print this help"
              :default false :flag true]
        ["-p" "--projectdir" "Project directory" :default "~/projecten/diskusage"]
        ["-db" "--database" "Database path" :default "~/projecten/diskusage/bigfiles.db"]
        ["-r" "--root" "Root directory to find big files in"])]
    (let [db-spec (db-spec-path db-spec-sqlite (:database opts))]
       (calc-md5! db-spec))))

(main *command-line-args*)

