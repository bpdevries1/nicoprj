#lang s-exp "delayed-lang.rkt"

(define (f x)
  (+ 1 x))

(f (/ 4 2))

(define (g y)
  2)

(g (/ 1 0))

(define (my-if tst thn els)
  (if (force* tst) thn els))

(+ (my-if #t 0 5) (my-if #f (/ 1 0) 1))
