#lang racket

(define-syntax-rule
  (module-count-and-print f ...)
  (#%module-begin (count-and-print f) ...))

(provide (rename-out [module-count-and-print #%module-begin])
         #%app #%datum +)

(provide
 (rename-out [module-count-and-print #%module-begin])
 (rename-out [interact-count-and-print #%top-interaction])
 (except-out (all-from-out racket)
             #%module-begin #%top-interaction))

;; [2016-10-19 17:05] blijkbaar worden hierdoor alle forms via count-and-print geleid.

(define-syntax-rule
  (count-and-print f)
  (begin (count++ 'f) f))

(define count 0)

(define (count++ f)
  (set! count (+ count 1))
  (displayln `(evaluating form ,count : ,f)))

;; om ook interactief te kunnen gebruiken.
;; waar is de punt voor?
(define-syntax-rule
  (interact-count-and-print . f)
  (count-and-print f))

