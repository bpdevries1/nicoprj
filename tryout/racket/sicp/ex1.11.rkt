#lang sicp

;; [2016-11-13 20:59] goal is to calculate cube root

(define (square x)
  (* x x))

(define (cube x)
  (* x x x))

(define (f1 x)
  (cond ((< x 3) x)
        (else (+ (f1 (- x 1))
                 (* 2 (f1 (- x 2)))
                 (* 3 (f1 (- x 3)))))))

;; i is current iteration, fi contains f2(i), fi-2 f2(i-2).
(define (f2 x)
  (define (f2-iter x i fi-2 fi-1 fi)
    (if (= i x)
        fi
        (f2-iter x (+ i 1) fi-1 fi
                 (+ fi
                    (* 2 fi-1)
                    (* 3 fi-2)))))
  (if (< x 3)
      x
      (f2-iter x 2 0 1 2)))
                

        