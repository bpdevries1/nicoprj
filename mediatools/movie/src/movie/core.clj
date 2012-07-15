(ns movie.core
  (:gen-class)
  (:require [net.cgrand.enlive-html :as html])
  ; (:require [movie.ddl])) ; met lobos, maar niet gelukt na een avondje stoeien.
  (:use [movie.dml]))

(defn fetch-url [url]
  (html/html-resource (java.net.URL. url)))

(defn imdb-movie-to-hashmap [m]
  "Creates a hashmap of a table-row in the IMDB Top 250 page (http://www.imdb.com/chart/top)"
  (let [[rank rating title-year] (map html/text (html/select m [:td]))
        [_ title year] (re-find #"^(.*) \((\d+)\)$" title-year)]
    (hash-map 
      :rank (re-find #"[^.]+" rank)
      :rating rating
      :title title
      :year year)))

(defn get-movies-imdb
  "Get IMDB movies from URL, return list of hash-maps, see imdb-movie-to-hashmap
   ex: (def movies (get-movies-imdb \"file:///home/nico/nicoprj/mediatools/movie/data/imdb-top250.html\"))  "
   [url]
   (->> (html/select (fetch-url url) [:tr])
       (drop 1)
       (take 250)
       (map imdb-movie-to-hashmap)))
       
