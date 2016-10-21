#lang br/quicklang
(require "parser.rkt")

(define (read-syntax path port)
  (define parse-tree (parse path (tokenize port)))
  (define module-datum `(module bf-mod "expander.rkt"
                          ,parse-tree))
  ;; kun je ipv hieronder ook #'module-datum gebruiken?
  (datum->syntax #f module-datum))
(provide read-syntax)

(require parser-tools/lex)
(define (tokenize port)
  (define (next-token)
    (define our-lexer
      (lexer
       [(eof) eof]
       [(char-set "><-.,+[]") lexeme] ; lexeme - direct character doorgeven.
       [any-char (next-token)])) ; moet dus wel next-token aanroepen, niet zo iets als ignore.
    (our-lexer port))
  next-token)
