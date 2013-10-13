(ns tutorial-client.post-processing)

; had hier eigenlijk een format-functie verwacht. Dit delen en afronden gaat niet altijd goed.
(defn- round [n places]
  (let [p (Math.pow 10 places)]
    (/ (Math.round (* p n)) p)))

(defn- round-number-post [[op path n]]
  [[op path (round n 2)]])

(defn add-post-processors [dataflow]
  (-> dataflow
      (update-in [:post :app-model] (fnil conj [])
                 [:value [:main :average-count] round-number-post])))

