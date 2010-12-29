; uit mex.pdf, soort tutorial over continuation style passing,
; om bv ontbreken van tail-recursive op te vangen.

(= 3 4)

(let ((ls '(1 2 3 4)))
(map (fn [x] (cons x ls)) ls))

(let [ls '(1 2 3 4)]
  (map (fn [x] (cons x ls)) ls))

(def mysum 
  (fn [n]
    (if (= n 0)
      0
      (+ n (mysum (- n 1))))))

(def mysum
  (fn [n acc]
    (if (= n 0)
      acc
      (mysum (- n 1) (+ n acc)))))

(def mysum
  (fn [n acc]
    (if (= n 0)
      acc
      (recur (- n 1) (+ n acc)))))      
      
;register form: functies zonder parameters, gebruik globals/registers
(def n (atom 0))
(def acc (atom 0))
(defn sum [] 
  (if (= @n 0)
    @acc
    (do (reset! acc (+ @n @acc))
        (reset! n (- @n 1))
        (recur))))
        
(defn mysum [my_n] 
  (def n (atom my_n))
  (def acc (atom 0))
  (sum))
        
;suspended goto form
(def sum
  (fn []
    (if (= @n 0)
      @acc
      (do
        (reset! acc (+ @n @acc))
        (reset! n (- @n 1))
        (fn [] (sum))))))
; hiermee is bv  (((((mysum 4))))) te doen, komt 10 uit

;stelling: (fn [] (f)) = f, de eta-rule van lambda calculus.
(def plus1 #'+)
(def plus2 (fn [] (#'+)))
; werkt niet, alleen voor functies zonder params

(defn const23 [] 23)
(def const23b (fn [] (const23)))

; eta-suspended goto-form:
(def sum
  (fn []
    (if (= @n 0)
      @acc
      (do
        (reset! acc (+ @n @acc))
        (reset! n (- @n 1))
        sum))))

; zelfde, hiermee ook (((((mysum 4))))) te doen.

; omzetten naar while/goto gebeuren.
(def sum
  (fn []
    (if (= @n 0)
      false
      (do
        (reset! acc (+ @n @acc))
        (reset! n (- @n 1))
        sum))))

; (= 0 0) gebruik ik hier als no-op.
(defn run []
  (while (sum) (= 0 0)) @acc)

(defn mysum [my_n] 
  (def n (atom my_n))
  (def acc (atom 0))
  (run))
 
;trampoline form: ook niet meer afhankelijk van return value
(def sum
  (fn []
    (if (= @n 0)
      (reset! action false)
      (do
        (reset! acc (+ @n @acc))
        (reset! n (- @n 1))
        (reset! action sum)))))

(defn run []
  (while @action (@action)) @acc)

(defn mysum [my_n] 
  (def n (atom my_n))
  (def acc (atom 0))
  (def action (atom sum))
  (run))

; terug naar het begin:
(def sum 
  (fn [n]
    (if (= n 0)
      0
      (+ n (sum (- n 1))))))

; aan elke lambda/fn een param cont toevoegen en deze apply-en to the body.
; ofwel de cont-functie aanroepen op de oorspronkelijk body met if.
; de id functie meegeven in beide aanroepen, van buiten en binnen.
(defn id [x] x)

(def sum 
  (fn [n cont]
    (cont
      (if (= n 0)
        0
        (+ n (sum (- n 1) id))))))
  
(defn mysum [n]
  (sum n id))

; idee om id door (+ n x) te vervangen?

; cont. door de branches van de if pushen, als de computation in de test-part (= n 0) simpel is.
(def sum 
  (fn [n cont]
    (if (= n 0)
      (cont 0)
      (cont (+ n (sum (- n 1) id))))))

; nu dealen met embedded (sum (- n 1)) call
; lijkt op het doorpushen van de continuation verder.
; hiermee wordt het weer tail-recursive.
(def sum 
  (fn [n cont]
    (if (= n 0)
      (cont 0)
      (sum (- n 1) (fn [acc]
          (cont (+ n acc)))))))

; free vars n en cont vervangen door let
; dit heet de preregister-tail form.
(def sum 
  (fn [n cont]
    (if (= n 0)
      (cont 0)
      (sum (- n 1) 
        (let [n n cont cont]
          (fn [acc]
            (cont (+ n acc))))))))

; hierna verder naar trampoline form.
; met apply-cont om talen zonder lambda's op te kunnen vangen.

(defn apply-cont [cont acc]
  (cont acc))

(def sum 
  (fn [n cont]
    (if (= n 0)
      (apply-cont cont 0)
      (sum (- n 1) 
        (let [n n cont cont]
          (fn [acc]
            (apply-cont cont (+ n acc))))))))

;representation-independent-preregister-tail form
(def id '())
(defn sum [n cont]  
  (if (= n 0)
    (apply-cont cont 0)
    (sum (- n 1) (cons n cont))))

(defn apply-cont [cont acc]
  (if (empty? cont)
    acc
    (apply-cont (rest cont) (+ (first cont) acc))))

; finally de trampoline form
; eerst nodig de atoms te defieren, voor def van sum
(defn id [x] x)

(def cont (atom id))
(def n (atom 0))
(def action (atom id))
(def acc (atom 0))

(defn sum []
  (if (= n 0)
    (do (reset! acc 0)
      (reset! action apply-cont))
    (do (reset! cont (cons n @cont))
      (reset! n (- @n 1))
      (reset! action sum))))

(defn apply-cont [] 
  (if (empty? @cont)
    (reset! action false)
    (do 
      (reset! acc (+ (first @cont) @acc))
      (reset! cont (rest @cont))
      (reset! action apply-cont))))

; bijna zelfde als voorheen, nu test op empty?
(defn run []
  (while (not (empty? @action)) (@action)) @acc)

(defn mysum [my_n]
  (def cont (atom id))
  (def n (atom my_n))
  (def action (atom sum))
  (run))

=> deze werkt nog niet:
java.lang.IllegalArgumentException: Don't know how to create ISeq from: user$sum__124 (NO_SOURCE_FILE:0)









