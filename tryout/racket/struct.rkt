#lang racket

(require rackunit)

(struct student (name id# dorm) #:transparent)

(define freshman1 (student 'Joe 1234 'NewHall))

(define mimi (student 'Mimi 1234 'NewHall))
(define nicole (student 'Nicole 5678 'NewHall))
(define rose (student 'Rose 8765 'NewHall))
(define eric (student 'Eric 4321 'NewHall))
(define in-class (list mimi nicole rose eric))
(student-id# (third in-class))

(define (my-length l)
  (cond [(empty? l) 0]
        [else (add1 (my-length (rest l)))]))

(struct point (x y) #:transparent)

(define (distance-to-origin p)
  (sqrt (+ (sqr (point-x p)) (sqr (point-y p)))))

;; some checks
(check-equal? (add1 6) 7)

(define (winning-players lst)
  (define sorted-lst (sort lst ...))
  (define (winners lst pred)
    (cond
      [(empty? lst) (list pred)]
      [else
       (define fst (first lst))
       (if (score> (record-score pred) (record-score fst))
           (list pred)
           (cons pred (winners (rest lst) fst)))]))
  ;; START HERE:
  (winners (rest sorted-lst) (first sorted-lst)))

