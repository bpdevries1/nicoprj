#lang br/quicklang
;; path - path naar de source, hier stacker-test.rkt
;; port - waarsch een handle naar deze file. Anders al de inhoud.
(define (read-syntax path port)
  (define src-lines (port->lines port))
  ;; format-datums lijkt een combi van map en format.
  (define src-datums (format-datums '(handle ~a) src-lines))
  ;; stacker.rkt is ook de expander, deze file dus.
  (define module-datum `(module stacker-mod "stacker.rkt"
                          ,@src-datums))
  (datum->syntax #f module-datum))

(provide read-syntax)


(define-macro (stacker-module-begin HANDLE-EXPR ...)
  ;; #' is om code in een syntax object om te zetten. Eigenlijk is dit dan alleen
  ;; de #, omdat de ' de code quote, zoals eerder, zie hierboven. Hier dan niet de #f
  ;; zoals hierboven, maar lexical context wordt gecaptured.
  #'(#%module-begin
     HANDLE-EXPR ...
     (display (first stack))))
(provide (rename-out [stacker-module-begin #%module-begin]))

(define stack empty)

(define (pop-stack!)
  (define item (first stack))
  (set! stack (rest stack))
  item)

(define (push-stack! item)
  (set! stack (cons item stack)))

;; optional arg op dezelfde manier als in Tcl.
(define (handle [arg #f])
  (cond
    [(number? arg) (push-stack! arg)]
    [(or (equal? + arg) (equal? * arg))
     (define op-result (arg (pop-stack!) (pop-stack!)))
     (push-stack! op-result)]))
(provide handle)

(provide + *)
