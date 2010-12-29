(with-data (read-xls "http://incanter.org/data/aus-airline-passengers.xls")
  (view $data))

(let [to-millis (fn [dates] (map #(.getTime %) dates))]
	  (view (time-series-plot (to-millis ($ :date)) ($ :passengers)))))
	  
(defn to-millis [dates] 
  (map #(.getTime %) dates))

(with-data (read-xls "http://incanter.org/data/aus-airline-passengers.xls")
  (view (time-series-plot (to-millis ($ :date)) ($ :passengers))))

(use '(incanter core datasets excel))
(save-xls (get-dataset :cars) "/tmp/cars.xls")

(def xls (read-xls "http://incanter.org/data/aus-airline-passengers.xls"))


; inlezen raw-data van sitescope
(use '(incater core io))

(def raw (read-dataset "/media/nas/aaa/offline.dat" :header false :delim \space))

(def raw11 ($where {:col0 {:eq "offline_datapoint_11"}} raw))

(view (scatter-plot :col1 :col2 :data raw11))

(defn raw-to-millis [raw]
  (map #(* 1000 %) raw))

(with-data raw11
  (view (time-series-plot (raw-to-millis ($ :col1)) ($ :col2)
    :title "CPU Usage on rc1waforce01"
    :x-label "Time"
    :y-label "CPU%")))

(with-data raw11
  (save (time-series-plot (raw-to-millis ($ :col1)) ($ :col2)
    :title "CPU Usage on rc1waforce01"
    :x-label "Time"
    :y-label "CPU%") "/media/nas/aaa/raw11.png"))

(use 'incanter.pdf)
(with-data raw11
  (save-pdf (time-series-plot (raw-to-millis ($ :col1)) ($ :col2)
    :title "CPU Usage on rc1waforce01"
    :x-label "Time"
    :y-label "CPU%") "/media/nas/aaa/raw11.pdf"))


