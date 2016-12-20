#lang racket

;; [2016-12-18 20:35] lists look better in racket language compared to sicp.
;; sicp shows mcons. So as long as the rest works...

#;(define (error . text)
    (write text)
    (/ 1 0))

(define (deriv exp var)
  (cond ((number? exp) 0)
        ((variable? exp)
         (if (same-variable? exp var) 1 0))
        ((sum? exp)
         (make-sum (deriv (addend exp) var)
                   (deriv (augend exp) var)))
        ((product? exp)
         (make-sum
          (make-product (multiplier exp)
                        (deriv (multiplicand exp) var))
          (make-product (deriv (multiplier exp) var)
                        (multiplicand exp))))
        ((exponentiation? exp)
         (make-product (exponent exp)
                       (make-exponentiation (base exp) (- (exponent exp) 1))))
        (else
         (error "unknown expression type -- DERIV" exp))))

(define (variable? x) (symbol? x))

(define (same-variable? v1 v2)
  (and (variable? v1) (variable? v2) (eq? v1 v2)))

#;(define (make-sum a1 a2) (list '+ a1 a2))

(define (make-sum a1 a2)
  (cond ((=number? a1 0) a2)
        ((=number? a2 0) a1)
        ((and (number? a1) (number? a2)) (+ a1 a2))
        (else (list '+ a1 a2))))

(define (=number? exp num)
  (and (number? exp) (= exp num)))


#;(define (make-product m1 m2) (list '* m1 m2))

(define (make-product m1 m2)
  (cond ((or (=number? m1 0) (=number? m2 0)) 0)
        ((=number? m1 1) m2)
        ((=number? m2 1) m1)
        ((and (number? m1) (number? m2)) (* m1 m2))
        (else (list '* m1 m2))))


(define (sum? x)
  (and (pair? x) (eq? (car x) '+)))

(define (addend s) (cadr s))

(define (augend s) (caddr s))

(define (product? x)
  (and (pair? x) (eq? (car x) '*)))

(define (multiplier p) (cadr p))

(define (multiplicand p) (caddr p))

(define (exponentiation? x)
  (and (pair? x) (eq? (car x) '**)))

(define (base e) (cadr e))
(define (exponent e) (caddr e))

(define (make-exponentiation base exp)
  (cond ((or (=number? base 0) (=number? base 1)) base)
        ((=number? exp 0) 1)
        ((=number? exp 1) base)
        (else (list '** base exp))))

;; tests
(deriv '(+ x 3) 'x)
;;(+ 1 0)

(deriv '(* x y) 'x)
;;(+ (* x 0) (* 1 y))

(deriv '(* (* x y) (+ x 3)) 'x)
#;(+ (* (* x y) (+ 1 0))
     (* (+ (* x 0) (* 1 y))
        (+ x 3)))

(make-exponentiation 2 0)

(deriv '(* 5 (** x 1)) 'x)

(deriv '(* 5 (** x 2)) 'x)

(deriv '(* 5 (** x 3)) 'x)