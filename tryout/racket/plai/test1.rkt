#lang plai-typed
;;#lang planet plai/plai:1:4
;; #lang plai-typed => not found

(define (plus x y) (+ x y))

;; bij #lang racket is define-type een unbound identifier.
;; define-type bestaat wel, maar number snapt 'ie hier niet.
(define-type MisspelledAnimal
  [caml (humps : number)]
  [yacc (height : number)])

(define ma1 : MisspelledAnimal (caml 2))
(define ma2 : MisspelledAnimal (yacc 1.9))

;; [2016-10-21 13:07] dit werkt ook, maar expliciet is hier beter.
;; (define ma1 (caml 2))
;; (define ma2 (yacc 1.9))

(define (good? [ma : MisspelledAnimal]) : boolean
  (type-case MisspelledAnimal ma
    [caml (humps) (>= humps 2)]
    [yacc (height) (> height 2.1)]))

(test (good? ma1) #t)
(test (good? ma2) #f)
;; (test (good? ma2) #t) ; bad.

;; zonder pattern matching:
(define (good2? [ma : MisspelledAnimal]) : boolean
  (cond
    [(caml? ma) (>= (caml-humps ma) 2)]
    [(yacc? ma) (> (yacc-height ma) 2.1)]))
