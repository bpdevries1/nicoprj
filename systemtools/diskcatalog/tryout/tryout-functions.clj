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


