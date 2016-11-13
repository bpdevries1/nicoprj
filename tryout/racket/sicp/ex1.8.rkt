#lang sicp

;; [2016-11-13 20:59] goal is to calculate cube root

(define (square x)
  (* x x))

(define (cube x)
  (* x x x))

(define (cbrt-iter prev-guess guess x)
  (if (good-enough? prev-guess guess)
      guess
      (cbrt-iter guess (improve guess x)
                 x)))

#;(define (improve guess x)
  (average guess (/ x guess)))

(define (improve guess x)
  (/ (+ (/ x (square guess)) (* 2 guess)) 3))

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


(define (cbrt x)
  (cbrt-iter 0.0 1.0 x))

;; some tests for small numbers
(cbrt 0.001)
(cube (cbrt 0.001))

(cbrt 1e-6)
(cube (cbrt 1e-6))

(cbrt 27.0)
(cbrt 1000.0)

(cbrt (cube 1000.0))
(cbrt (cube 10000.0))
;(cbrt (cube 100000.0))
;(cbrt (cube 1000000.0))
;(cbrt (cube 10000000.0))
;(cbrt (cube 100000000.0))
;(cbrt (cube 1000000000.0))

;; now even larger
(cbrt (cube 1000000000000.0))
(cbrt (cube 1000000000000000.0))
