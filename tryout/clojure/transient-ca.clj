(import '(javax.swing JFrame)        
        '(java.awt Color Graphics Canvas GraphicsEnvironment
                   GraphicsDevice GraphicsConfiguration Graphics2D)
        '(java.awt.image BufferedImage BufferStrategy))

(def dim-board   [130  130])
(def dim-screen  [600  600])
(def dim-scale   (vec (map / dim-screen dim-board)))

(def board-size (apply * dim-board))
(def board      (-> (vec (repeat board-size :off))
                    (assoc (/ (dim-board 0) 2)       :on)
                    (assoc (inc (/ (dim-board 0) 2)) :on)))

(def cords (for [y (range (dim-board 0)) x (range (dim-board 1))] [x y]))

(defn torus-coordinate
  [idx]
  (cond (neg? idx)          (+ idx board-size)
        (>= idx board-size) (- idx board-size)
    :else idx))

(def above     (- (dim-board 0)))
(def below     (dim-board 0))
(def neighbors [-1 1 (dec above) above (inc above) (dec below) below (inc below)])

(defn on-neighbors [i board]
  (count
   (filter #(= :on (nth board %))
           (map #(torus-coordinate (+ i %)) neighbors))))

(defn step [board]  
  (loop [i 0 next-state (transient board)]
    (if (< i board-size)
      (let [self         (nth board i)]
        (recur (inc i)
               (assoc! next-state i (cond
                                      (= :on    self)                :dying
                                      (= :dying self)                :off
                                      (= 2 (on-neighbors i board))   :on
                                      :else                          :off))))
      (persistent! next-state))))

(defn render-cell [#^Graphics g [x y] state]
  (when-not (= :off state)
    (let [x  (inc (* x (dim-scale 0)))
          y  (inc (* y (dim-scale 1)))]
      (doto g
        (.setColor (if (= state :on) Color/WHITE Color/GRAY))
        (.fillRect x y (dim-scale 0) (dim-scale 1))))))

(defn render-scene [g2d buffer bi stage]
  (doto #^Graphics2D g2d
    (.setColor Color/BLACK)
    (.fillRect 0 0 (dim-screen 0) (dim-screen 1)))
  (dorun (map #(render-cell g2d %1 %2) cords stage))
  (.drawImage (.getDrawGraphics #^BufferStrategy buffer) bi 0 0 nil)
  (when (not (.contentsLost #^BufferStrategy buffer))
    (.show #^BufferStrategy buffer)))

(defn activity-loop [canvas stage]
  (let [buffer (.getBufferStrategy canvas)
        bi     (.. (GraphicsEnvironment/getLocalGraphicsEnvironment)
                   (getDefaultScreenDevice) (getDefaultConfiguration)
                   (createCompatibleImage (dim-screen 0) (dim-screen 1)))
        g2d    (.createGraphics bi)]
    (while true
      (swap! stage step)
      (future (render-scene g2d buffer bi @stage)))))

(let [stage   (atom board)
      frame   (JFrame.)
      canvas  (doto (Canvas.) (.setIgnoreRepaint true)
                    (.setSize (dim-screen 0) (dim-screen 1)))
      window  (doto (JFrame.) (.add canvas) .pack .show
                    (.setDefaultCloseOperation JFrame/EXIT_ON_CLOSE)
                    (.setIgnoreRepaint true))]
  (.createBufferStrategy canvas 2)
  (future (activity-loop canvas stage)))