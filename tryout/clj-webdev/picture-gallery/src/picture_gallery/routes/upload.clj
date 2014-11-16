(ns picture-gallery.routes.upload
  (:require [compojure.core :refer [defroutes GET POST]]
            [hiccup.form :refer :all]
            [hiccup.element :refer [image]]
            [hiccup.util :refer [url-encode]]
            [picture-gallery.views.layout :as layout]
            [noir.io :refer [upload-file resource-path]]
            [noir.session :as session]
            [noir.response :as resp]
            [noir.util.route :refer [restricted]]
            [clojure.java.io :as io]
            [ring.util.response :refer [file-response]]
            [picture-gallery.models.db :as db]
            [noir.util.route :refer [restricted]]
            [picture-gallery.models.db :as db]
            [picture-gallery.util :refer [galleries gallery-path thumb-prefix thumb-uri]]
            [taoensso.timbre :refer [trace debug info warn error fatal]])
  (:import [java.io File FileInputStream FileOutputStream]
           [java.awt.image AffineTransformOp BufferedImage]
           java.awt.RenderingHints
           java.awt.geom.AffineTransform
           javax.imageio.ImageIO))

(def thumb-size 150)

(defn scale [img ratio width height]
  (let [scale (AffineTransform/getScaleInstance
               (double ratio) (double ratio))
        transform-op (AffineTransformOp.
                      scale AffineTransformOp/TYPE_BILINEAR)]
    (.filter transform-op img (BufferedImage. width height (.getType img)))))

#_(ImageIO/write
 (scale (ImageIO/read (io/input-stream "image.png")) 0.5 150 150)
 "png"
 (File. "scaled.png"))

(defn scale-image [file]
  (let [img        (ImageIO/read file)
        img-width  (.getWidth img)
        img-height (.getHeight img)
        ratio      (/ thumb-size img-height)]
    (scale img ratio (int (* img-width ratio)) thumb-size)))

#_(ImageIO/write
 (scale-image (io/input-stream "image.png"))
 "png"
 (File. "scaled.png"))

; @todo use actual File function?
(defn file-ext [filename]
  (last (clojure.string/split filename #"\.")))

(defn save-thumbnail [{:keys [filename]}]
  (let [path (str (gallery-path) File/separator)]
    (ImageIO/write
     (scale-image (io/input-stream (str path filename)))
     (file-ext filename) ; @todo should determine file extension here. Or better the actual image type.
     (File. (str path thumb-prefix filename)))))

; showing the upload page (?) and redirect to this one after upload (?)
(defn upload-page [info]
  (println "On the upload page...")
  (layout/common
   [:h2 "Upload an image"]
   [:p info]
   (form-to {:enctype "multipart/form-data"}
            [:post "/upload"]
            (file-upload :file)
            (submit-button "upload"))))

; handle the posting on the upload page
(defn handle-upload [{:keys [filename] :as file}]
  (println "file: " file)
  (println "filename: " filename)
  (upload-page
    (if (empty? filename)
      "please select a file to upload"
      ; else
      (try
        ; (upload-file (gallery-path) file :create-path? true)
        (upload-file (gallery-path) file)
        (save-thumbnail file)
        (db/add-image (session/get :user) filename)
        (image {:height "150px"}
               ; (str "/img/" (session/get :user) "/" thumb-prefix (url-encode filename)))
               (thumb-uri (session/get :user) filename))
        (catch Exception ex
          (str ("error uploading file " (.getMessage ex))))))))

(defn serve-file [user-id file-name]
  (info "serve file (log): " file-name)
  (println "serve-file: " file-name)
  (file-response (str galleries File/separator user-id File/separator file-name)))

(defn delete-image [userid name]
  (println "delete-file: " name)
  (try
    (db/delete-image userid name)
    (io/delete-file (str (gallery-path) File/separator name))
    (io/delete-file (str (gallery-path) File/separator thumb-prefix name))
    "ok"
    (catch Exception ex
      (error ex "an error has occured while deleting" name)
      (.getMessage ex))))

(defn delete-images [names]
  (println "delete images: " names)
  (let [userid (session/get :user)]
    (resp/json
     (for [name names] {:name name :status (delete-image userid name)}))))

(defroutes upload-routes
  (GET "/upload" [info] (restricted (upload-page info)))
  (POST "/upload" [file] (restricted (handle-upload file)))
  (GET "/img/:user-id/:file-name" [user-id file-name]
       (serve-file user-id file-name))
  (POST "/delete" [names] (restricted (delete-images names))))

