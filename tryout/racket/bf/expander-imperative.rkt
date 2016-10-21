#lang br/quicklang

(define-macro (bf-module-begin PARSE-TREE)
  #'(#%module-begin
     PARSE-TREE))
(provide (rename-out [bf-module-begin #%module-begin]))

(define-macro (bf-program OP-OR-LOOP-ARG ...)
  #'(void OP-OR-LOOP-ARG ...))
(provide bf-program)

(define-macro (loop "[" OP-OR-LOOP-ARG ... "]")
  #'(until (zero? (current-byte)) ; function coming soon
           OP-OR-LOOP-ARG ...))
(provide loop)

(define-macro-cases op
  [(op ">") #'(gt)]        ; We have
  [(op "<") #'(lt)]        ; not made
  [(op "+") #'(plus)]      ; these functions
  [(op "-") #'(minus)]     ; yet, but
  [(op ".") #'(period)]    ; we will
  [(op ",") #'(comma)])    ; shortly.
(provide op)

(define arr (make-vector 30000 0))
(define ptr 0)

(define (current-byte) (vector-ref arr ptr))
(define (set-current-byte! val) (vector-set! arr ptr val))

(define (gt) (set! ptr (add1 ptr)))
(define (lt) (set! ptr (sub1 ptr)))

(define (plus) (set-current-byte! (add1 (current-byte))))
(define (minus) (set-current-byte! (sub1 (current-byte))))

(define (period) (write-byte (current-byte)))
(define (comma) (set-current-byte! (read-byte)))
