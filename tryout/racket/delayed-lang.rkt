#lang racket

(provide
 (rename-out [delayed-args-app #%app])
 #%datum #%module-begin #%top-interaction
 define if force* (rename-out [+force +] [/force /]))

(define-syntax-rule
  (delayed-args-app f a ...)
  (#%app f (delay a) ...))

(define (+force a b)
  (+ (force* a) (force* b)))

(define (/force a b)
  (/ (force* a) (force* b)))

(define (force* x)
  (if (promise? x) (force* (force x)) x))
