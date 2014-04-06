#!/bin/bash lein-exec

(load-file "/home/nico/nicoprj/clojure/lib/def-libs.clj") 

(defn det-series [target-root]
  ; find-files is recursive, don't want that, so use glob, which isn't recursive.
  (->> (fs/glob (io/as-file target-root) "*")
       (filter fs/directory?)
       ;(filter #(not (.isFile %)))
       (map fs/base-name)))

(defn file-is-serie? 
  "Check if filename corresponds to serie, by checking if each word in serie occurs in filename"
  [filename serie]
  (let [filetail (str/lower-case (fs/base-name filename))]
    (every? #(re-find (re-pattern %) filetail) 
      (str/split (str/lower-case serie) #"[ '()]"))))

(defn det-serie-season 
  "Determine serie and season of a filename using series sequence"
  [filename series]
  (if-let [serie (first (filter (partial file-is-serie? filename) series))]
    (if-let [season (second (re-find #"(?i)s(\d+)e\d+" (fs/base-name filename)))]
      [serie (Integer/parseInt season)])))

; @todo first try rename (same filesystem), if it fails, do the copy/delete action.
; @todo follow symlinks for both paths: if same filesystem, use 'absolute' paths so rename is a fast move, not a copy/delete.
(defn move-file 
  "Move/rename file, print details, create target dir"
  [src target]
  (println (str "Move " src " => " target))
  (if (fs/copy+ src target)
    (do (.setLastModified target (.lastModified src))
        (fs/delete src))
    (println (str "Failed to move file: " src " to " target)))) 

(defn move-serie-file
  "Move series file to target"
  [filename target-root serie season]
  (move-file filename (fs/file target-root serie (str "Season " season) (fs/base-name filename))))

(defn handle-file 
  "Move a single series file to target dir within target-root based on series" 
  [filename target-root series]
  (comment (println (str "Handling file: " filename)))
  (if-let [[serie season] (det-serie-season filename series)]
    (move-serie-file filename target-root serie season)))

(defn cleanup-dir 
  "Remove directory dirname iff it has no big files (>10MB) and subdirs in it (anymore)"
  [dirname]
  (let [pathnames (fs/glob dirname "*")
        subdirs (filter fs/directory? pathnames)
        bigfiles (filter #(> (fs/size %) 1e7) pathnames)]
    (if (and (empty? subdirs) (empty? bigfiles))
      (do (println (str "About to delete empty dir: " dirname))
          (fs/delete-dir dirname))
      (println (str "Dir not empty: " dirname)))))
  
(defn handle-dir [dirname target-root series]
  (comment (println (str "Handling dir: " dirname)))
  (if-let [[serie season] (det-serie-season dirname series)]
    (let [filenames (->> (fs/glob dirname "*")
                         (filter #(#{".avi" ".mp4" ".mkv"} (fs/extension %))))]
      (doseq [filename filenames]
        (move-serie-file filename target-root serie season))
      (cleanup-dir dirname))))

(defn handle-dir-root [src-root target-root series]
  ; file-seq is recursive, do not want that.
  (doseq [filename (fs/glob (fs/file src-root) "*")]
    (if (fs/file? filename)
      (handle-file filename target-root series)
      (handle-dir filename target-root series))))

(defn main []
  (let [target-root "/media/nico/Iomega HDD/media/Series"
        src-root "/home/nico/media/tijdelijk"
        series (det-series target-root)]
    (println (str "Series: " (vec series))) ; vec needed to coerce lazy seq to vector, to print it.
    (handle-dir-root src-root target-root series)
    (handle-dir-root (fs/file src-root "Series") target-root series)))

(main)

