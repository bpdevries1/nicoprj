#lang sicp

;; [2016-11-13 20:13] goal is to increase precision for small numbers

(define (square x)
  (* x x))

(define (sqrt-iter prev-guess guess x)
  (if (good-enough? prev-guess guess)
      guess
      (sqrt-iter guess (improve guess x)
                 x)))

(define (improve guess x)
  (average guess (/ x guess)))

(define (average x y)
  (/ (+ x y) 2))

#;(define (good-enough? guess x)
  (< (abs (- (square guess) x)) 0.001))

;; maybe still rounding errors when substracting 2 small numbers
;; better to divide both guesses? Then check if value is between 1-epsilon and 1+epsilon
#;(define (good-enough? prev-guess guess)
  (< (abs (/ (- prev-guess guess) guess)) 0.001))

(define (good-enough? prev-guess guess)
  (within-epsilon? (/ prev-guess guess) 1.0 0.00001))

(define (within-epsilon? val goal epsilon)
  (< (- goal epsilon) val (+ goal epsilon)))


(define (sqrt x)
  (sqrt-iter 0.0 1.0 x))

;; some tests for small numbers
(sqrt 0.01)
(square (sqrt 0.01))

(sqrt 0.0001)
(square (sqrt 0.0001))

(sqrt (square 1000.0))
(sqrt (square 10000.0))
;(sqrt (square 100000.0))
;(sqrt (square 1000000.0))
;(sqrt (square 10000000.0))
;(sqrt (square 100000000.0))
;(sqrt (square 1000000000.0))

;; now even larger
(sqrt (square 1000000000000.0))
(sqrt (square 1000000000000000.0))
