#lang racket
#|
Stuk langer commentaar
over meerdere regels.
|#
;; [2016-10-17 12:03] lower en upper hoeven hier nog niet defined te zijn
(define (start n m)
  (set! lower (min n m))
  (set! upper (max n m))
  (guess))

(define lower 1)
(define upper 100)

(define (guess)
  (quotient (+ lower upper) 2))

(define (smaller)
  (set! upper (max lower (sub1 (guess))))
  (guess))

(define (bigger)
  (set! lower (min upper (add1 (guess))))
  (guess))

;; verlijkbaar met clojure #_ form?
#;(start)
