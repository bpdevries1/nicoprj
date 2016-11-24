#lang sicp

;; [2016-11-21 21:24] goal is to calculate Pascal's Triangle.

;; recursive process
;; skew triangle to the right, so the left part is vertical
;; return -1 if indexes are wrong.
;; x and y index both start at 0
;; (pascal 0 0) = 1
;; (pascal 0 x) = 1
;; (pascal x x) = 1
;; (pascal x y) = (+ (pascal x (- y 1)) (pascal (- x 1) (- y 1)))
(define (pascal x y)
  (cond
    ((> x y) -1)
    ((< x 0) -1)
    ((< y 0) -1)
    ((= x 0) 1)
    ((= x y) 1)
    (else (+ (pascal x (- y 1))
             (pascal (- x 1) (- y 1))))))
;; this one is straight forward, nothing deep to learn here?

;; iterative process to calculate each line, need concat or similar, and map as well.
;; append to concat lists.
;; this one is (still) O(n^2) in nr of processing steps, O(n) in space.
(define (drop-last lst)
  (reverse (cdr (reverse lst))))

(define (pascal2 row)  
  (define (pascal2-iter row i row-i)
    (cond
      ((= row i) row-i)
      (else
       (pascal2-iter row (+ i 1)
                     (append
                      '(1)
                      (map + (drop-last row-i) (cdr row-i))
                      '(1))))))
  (cond
    ((< row 0) -1)
    (else (pascal2-iter row 0 '(1)))))
