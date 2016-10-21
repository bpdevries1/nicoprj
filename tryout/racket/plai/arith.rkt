#lang plai-typed

;; ArithC is de C van Core.
(define-type ArithC
  [numC (n : number)]
  [plusC (l : ArithC) (r : ArithC)]
  [multC (l : ArithC) (r : ArithC)])

;; [2016-10-21 14:58] parse nu naar ArithS, dus deze weg.
#;(define (parse [s : s-expression]) : ArithC
  (cond
    [(s-exp-number? s) (numC (s-exp->number s))]
    [(s-exp-list? s)
     (let ([sl (s-exp->list s)])
       (case (s-exp->symbol (first sl))
         [(+) (plusC (parse (second sl)) (parse (third sl)))]
         [(*) (multC (parse (second sl)) (parse (third sl)))]
         [else (error 'parse "invalid list input")]))]
    [else (error 'parse "invalid input")]))

;; [2016-10-21 13:34] ok, dit werkt hierboven, maar BR manier lijkt handiger, met een grammar.
(define (interp [a : ArithC]) : number
  (type-case ArithC a
    [numC (n) n]
    [plusC (l r) (+ (interp l) (interp r))]
    [multC (l r) (* (interp l) (interp r))]))


;; [2016-10-21 14:55] Surface syntax, tegenhanger van Core. Deze met minus.
(define-type ArithS
  [numS (n : number)]
  [plusS (l : ArithS) (r : ArithS)]
  [bminusS (l : ArithS) (r : ArithS)]
  [multS (l : ArithS) (r : ArithS)])

;; idee is dan van s-expr via Surface naar Core datatype.
;; van s-expr naar Surface via parse functie.
;; van Surface naar Core wordt dan desugar genoemd.
;; en van Core->uitkomst (number hier) nog steeds in interp, verandert niet.
;; vraag of je (interp (desugar (parse))) wilt, of dat desugar bv bij parse inzit.
;; voorlopig los houden.
(define (parse [s : s-expression]) : ArithS
  (cond
    [(s-exp-number? s) (numS (s-exp->number s))]
    [(s-exp-list? s)
     (let ([sl (s-exp->list s)])
       (case (s-exp->symbol (first sl))
         [(+) (plusS (parse (second sl)) (parse (third sl)))]
         [(-) (bminusS (parse (second sl)) (parse (third sl)))]
         [(*) (multS (parse (second sl)) (parse (third sl)))]
         [else (error 'parse "invalid list input")]))]
    [else (error 'parse "invalid input")]))

;; TODO: desugar. Moet wel alles langs en omzetten van S->C.
;; eerst via cond, later ook type case, pattern match?
#;(define (desugar [s : ArithS]) : ArithC
  (cond
    [(numS? s) (numC (numS-n s))]
    [(plusS? s) (plusC (desugar (plusS-l s)) (desugar (plusS-r s)))]
    [(bminusS? s) (plusC (desugar (bminusS-l s))
                        (multC (numC -1) (desugar (bminusS-r s))))]
    [(multS? s) (multC (desugar (multS-l s)) (desugar (multS-r s)))]
    [else (error 'desugar42 "invalid input")]))

;; [2016-10-21 13:50] Test cases for interpreter
;; en moeten via ArithS nog steeds werken.
;; threading (->) operator zou hier ook handig zijn.
#|
(test (interp (desugar (parse '0))) 0)
(test (interp (desugar (parse '23))) 23)
(test (interp (desugar (parse '(+ 1 2)))) 3)
(test (interp (desugar (parse '(* 3 2)))) 6)
(test (interp (desugar (parse '(+ (* 3 4) (+ 2 3))))) 17)
(test (interp (desugar (parse '(+ 1.0 2.5)))) 3.5)
(test (interp (desugar (parse '(+ 1/4 1/3)))) 7/12)

(test (interp (desugar (parse '(- 8 6)))) 2)
(test (interp (desugar (parse '(- 8 (* 2 3))))) 2)
|#

;; [2016-10-21 15:51] ok, dit werkt. Dan ook met type case / pattern match.
;; [2016-10-21 16:06] grappig: else case is unreachable nu.
(define (desugar [s : ArithS]) : ArithC
  (type-case ArithS s ; waarom beide nodig? s om aan te geven over welke param het gaat. ArithS: dat je 'em op dit niveau in de class-tree wilt bekijken.
    [numS (n) (numC n)]
    [plusS (l r) (plusC (desugar l) (desugar r))]
    [multS (l r) (multC (desugar l) (desugar r))]
    [bminusS (l r) (plusC (desugar l) (multC (numC -1) (desugar r)))]))

;; [2016-10-21 16:21] ook unary minus erbij:
(test (interp (desugar (parse '0))) 0)
(test (interp (desugar (parse '23))) 23)
(test (interp (desugar (parse '(+ 1 2)))) 3)
(test (interp (desugar (parse '(* 3 2)))) 6)
(test (interp (desugar (parse '(+ (* 3 4) (+ 2 3))))) 17)
(test (interp (desugar (parse '(+ 1.0 2.5)))) 3.5)
(test (interp (desugar (parse '(+ 1/4 1/3)))) 7/12)
(test (interp (desugar (parse '(- 8 6)))) 2)
(test (interp (desugar (parse '(- 8 (* 2 3))))) 2)
;; (test (interp (desugar (parse '(- 1)))) -1)

    