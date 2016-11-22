#lang sicp

;; [2016-11-13 20:59] goal is to calculate cube root

(define (square x)
  (* x x))

(define (cube x)
  (* x x x))

(define (A x y)
  (cond ((= y 0)
         0)
        ((= x 0)
         (* 2 y))
        ((= y 1)
         2)
        (else (A
               (- x 1)
               (A x (- y 1))))))

(define (f n)
  (A 0 n))

(define (g n)
  (A 1 n))

(define (h n)
  (A 2 n))

(define (k n)
  (* 5 n n))

#;(A 1 10)
#;(A 2 4)
#;(A 3 3)
