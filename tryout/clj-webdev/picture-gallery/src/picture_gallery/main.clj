(ns picture-gallery.main
  (:use picture-gallery.handler
        [org.httpkit.server :only [run-server]]
        [ring.middleware file-info file])
  (:gen-class))

(defn -main [& [port]]
  (let [port (if port (Integer/parseInt port) 3000)]
    (run-server app {:port port})
    (println (str "You can view the site at http://localhost:" port))))
