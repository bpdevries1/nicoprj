#lang plai-typed

;; [2016-10-21 18:57] of deze ter vervanging van ArithC.
;; idd melding dat numC nu dubbel is.
;; [2016-10-21 19:00] Deze manier van definieren lijkt wel ok, vergelijkbaar met Grammar.
;;   desugar en interp ook wel ok, alleen parse nog vrij omslachtig.
(define-type ExprC
  [numC (n : number)]
  [idC (s : symbol)]
  [appC (fun : symbol) (arg : ExprC)]
  [plusC (l : ExprC) (r : ExprC)]
  [multC (l : ExprC) (r : ExprC)]
  [eqC (l : ExprC) (r : ExprC)]
  [ifC (c : ExprC) (t : ExprC) (e : ExprC)])

;;(appC 'double (numC 5))

;; [2016-10-21 18:52] Add functions, first with one parameter.
(define-type FunDefC
  [fdC (name : symbol) (arg : symbol) (body : ExprC)])

;; (fdC 'double 'x (plusC (idC 'x) (idC 'x)))

(define-type ExprS
  [numS (n : number)]
  [plusS (l : ExprS) (r : ExprS)]
  [bminusS (l : ExprS) (r : ExprS)]
  [uminusS (l : ExprS)]
  [multS (l : ExprS) (r : ExprS)]
  [eqS (l : ExprS) (r : ExprS)]
  [ifS (c : ExprS) (t : ExprS) (e : ExprS)])

;; [2016-10-21 19:57] for now return the double function.
;; [2016-10-21 20:18] deze def ging goed, ook al is 'ie niet typed.
#;(define (get-fundef name lofundefs)
  (fdC 'double 'x (plusC (idC 'x) (idC 'x))))

;; [2016-10-21 20:21] had gehoopt dat dit met iets meer higher-level functie kon:
;; bv direct met een hashmap.
(define (get-fundef [n : symbol] [fds : (listof FunDefC)]) : FunDefC
  (cond
    [(empty? fds) (error 'get-fundef "reference to undefined function")]
    [(cons? fds) (cond
                   [(equal? n (fdC-name (first fds))) (first fds)]
                   [else (get-fundef n (rest fds))])]))


;; [2016-10-21 19:05] new version including functions.
;; vraag wordt gesteld wat je bij idC zou moeten doen: lijkt dat dit niet voor mag komen,
;; een unbound identifier, zowel in de hoofdexpressie e als in de body van definitions waarbij
;; de identifier niet subst-ed is. Kan nu een error geven, kijken wat 'ie doet.
;; [2016-10-21 21:49] Door inter-subst bij appC wordt eager application gedaan.
#;(define (interp [e : ExprC] [fds : (listof FunDefC)]) : number
  (type-case ExprC e
    [numC (n) n]
    ;; <idC-interp-case>
    ;; [2016-10-21 20:17] zelf wel goed verzonnen, moet idd fout gaan!
    [idC (s) (error 'id "Unbound identifier")]
    [appC (f a) (local ([define fd (get-fundef f fds)])
                  (interp (subst (interp a fds)
                                 (fdC-arg fd)
                                 (fdC-body fd))
                          fds))]
    [plusC (l r) (+ (interp l fds) (interp r fds))]
    [multC (l r) (* (interp l fds) (interp r fds))]
    [eqC (l r) (if (= (interp l fds) (interp r fds)) 1 0)]
    [ifC (c t e) (if (= 0 (interp c fds)) (interp e fds) (interp t fds))]))

;; in appC (begin (define)) gebruiken -> define not allowed in expression context.
;; met let -> werkt prima zo te zien.
;; mss moet je local gebruiken zodat je niet (meer) in expression context zit.
(define (interp [e : ExprC] [fds : (listof FunDefC)]) : number
  (type-case ExprC e
    [numC (n) n]
    ;; <idC-interp-case>
    ;; [2016-10-21 20:17] zelf wel goed verzonnen, moet idd fout gaan!
    [idC (s) (error 'id "Unbound identifier")]
    [appC (f a) (let ([fd (get-fundef f fds)])
                  (interp (subst (interp a fds)
                                 (fdC-arg fd)
                                 (fdC-body fd))
                          fds))]
    [plusC (l r) (+ (interp l fds) (interp r fds))]
    [multC (l r) (* (interp l fds) (interp r fds))]
    [eqC (l r) (if (= (interp l fds) (interp r fds)) 1 0)]
    [ifC (c t e) (if (= 0 (interp c fds)) (interp e fds) (interp t fds))]))


;; [2016-10-21 19:09] helper function, waar is * voor? Of beetje CT achtig, dat je
;; de domeinen vermenigvuldigt.

;; get-fundef : symbol * (listof FunDefC) -> FunDefC

;; subst : ExprC * symbol * ExprC -> ExprC
;; 'what' lijkt expression, 'in' lijkt de functie-def body.
;; een soort regsub -all $for $in $what in2
;; hier zouden ook weer eqC en ifC gechecked moeten worden. Ook dit lijkt wat omslachtig,
;;  moet ook beter kunnen. Soort 'recur' patroon.
;; [2016-10-21 21:55] name-capture zou hier nog fout zijn, maar wordt hierin
;; blijkbaar niet zichtbaar.
(define (subst [what : number] [for : symbol] [in : ExprC]) : ExprC
  (type-case ExprC in
    [numC (n) in]
    [idC (s) (cond
               [(symbol=? s for) (numC what)]
               [else in])]
    [appC (f a) (appC f (subst what for a))]
    [plusC (l r) (plusC (subst what for l)
                        (subst what for r))]
    [multC (l r) (multC (subst what for l)
                        (subst what for r))]
    [eqC (l r) (eqC (subst what for l) (subst what for r))]
    [ifC (c t e) (ifC (subst what for c) (subst what for t)
                      (subst what for e))]))

#|
• (fdC 'double 'x (plusC (idC 'x) (idC 'x)))
• (fdC 'quadruple 'x (appC 'double (appC 'double (idC 'x))))
• (fdC 'const5 '_ (numC 5))

Suppose we want to substitute 3 for the identifier x in the bodies of the
three example functions above. What should it produce?

• (fdC 'double 'x (plusC (idC 'x) (idC 'x)))
=>
• (fdC 'double 'x (plusC (numC 3) (numC 3)))

• (fdC 'quadruple 'x (appC 'double (appC 'double (idC 'x))))
• (fdC 'const5 '_ (numC 5))

(idC 'x) => (numC 3)

|#


;; idee is dan van s-expr via Surface naar Core datatype.
;; van s-expr naar Surface via parse functie.
;; van Surface naar Core wordt dan desugar genoemd.
;; en van Core->uitkomst (number hier) nog steeds in interp, verandert niet.
;; vraag of je (interp (desugar (parse))) wilt, of dat desugar bv bij parse inzit.
;; voorlopig los houden.
(define (parse [s : s-expression]) : ExprS
  (cond
    [(s-exp-number? s) (numS (s-exp->number s))]
    [(s-exp-list? s)
     (let ([sl (s-exp->list s)])
       (case (s-exp->symbol (first sl))
         [(+) (plusS (parse (second sl)) (parse (third sl)))]
         [(-) (if (= 3 (length sl))
                  (bminusS (parse (second sl)) (parse (third sl)))
                  (uminusS (parse (second sl))))]
         [(*) (multS (parse (second sl)) (parse (third sl)))]
         [(=) (eqS (parse (second sl)) (parse (third sl)))]
         [(if) (ifS (parse (second sl)) (parse (third sl)) (parse (fourth sl)))]
         [else (error 'parse "invalid list input")]))]
    [else (error 'parse "invalid input")]))

;; [2016-10-21 15:51] ok, dit werkt. Dan ook met type case / pattern match.
;; [2016-10-21 16:06] grappig: else case is unreachable nu.
#;(define (desugar [s : ArithS]) : ArithC
    (type-case ArithS s ; waarom beide nodig? s om aan te geven over welke param het gaat. ArithS: dat je 'em op dit niveau in de class-tree wilt bekijken.
      [numS (n) (numC n)]
      [plusS (l r) (plusC (desugar l) (desugar r))]
      [multS (l r) (multC (desugar l) (desugar r))]
      [bminusS (l r) (plusC (desugar l) (multC (numC -1) (desugar r)))]
      [uminusS (l) (multC (numC -1) (desugar l))]
      [eqS (l r) (eqC (desugar l) (desugar r))]
      [ifS (c t e) (ifC (desugar c) (desugar t) (desugar e))]))

(define (desugar [s : ExprS]) : ExprC
  (type-case ExprS s ; waarom beide nodig? s om aan te geven over welke param het gaat. ArithS: dat je 'em op dit niveau in de class-tree wilt bekijken.
    [numS (n) (numC n)]
    [plusS (l r) (plusC (desugar l) (desugar r))]
    [multS (l r) (multC (desugar l) (desugar r))]
    [bminusS (l r) (plusC (desugar l) (multC (numC -1) (desugar r)))]
    [uminusS (l) (multC (numC -1) (desugar l))]
    [eqS (l r) (eqC (desugar l) (desugar r))]
    [ifS (c t e) (ifC (desugar c) (desugar t) (desugar e))]))


;; [2016-10-21 16:21] ook unary minus erbij:
(test (interp (desugar (parse '0)) (list)) 0)

;; [2016-10-21 20:10] desugar en parse moeten nog bijgewerkt worden.
;; dus eerst direct ExprC variant.

;; [2016-10-21 22:18] zowaar mogelijk hiermee een werkende fac functie te maken!
(define fds (list (fdC 'double 'x (plusC (idC 'x) (idC 'x)))
                  (fdC 'fac 'x (ifC (eqC (idC 'x) (numC 1))
                                    (numC 1)
                                    ; else
                                    (multC (idC 'x)
                                           (appC 'fac (plusC (numC -1)
                                                             (idC 'x))))))))

(test (interp (appC 'double (numC 5)) fds) 10)
(test (interp (appC 'double (plusC (numC 2) (numC 4))) fds) 12)

(test (interp (appC 'fac (numC 1)) fds) 1)
(test (interp (appC 'fac (numC 2)) fds) 2)
(test (interp (appC 'fac (numC 3)) fds) 6)
(test (interp (appC 'fac (numC 6)) fds) 720)

;; deze gaat waarsch een stack overflow opleveren.
;; maar het duurt wel even...
;; ... maar gestopt, fans gingen blazen.
;; (test (interp (appC 'fac (numC 0)) fds) 1)

;; deze 2 leveren exceptie op zoals verwacht: unbound identifier, zowel voor 'a als 'x.
;; (test (interp (appC 'double (idC 'a)) fds) 10)
;; (test (interp (appC 'double (idC 'x)) fds) 10)

#|
(test (interp (desugar (parse '23))) 23)
(test (interp (desugar (parse '(+ 1 2)))) 3)
(test (interp (desugar (parse '(* 3 2)))) 6)
(test (interp (desugar (parse '(+ (* 3 4) (+ 2 3))))) 17)
(test (interp (desugar (parse '(+ 1.0 2.5)))) 3.5)
(test (interp (desugar (parse '(+ 1/4 1/3)))) 7/12)
(test (interp (desugar (parse '(- 8 6)))) 2)
(test (interp (desugar (parse '(- 8 (* 2 3))))) 2)
(test (interp (desugar (parse '(- 1)))) -1)

;; [2016-10-21 16:50] exercise: add conditionals, minimal:
;; add = operator, return 1 when equal, 0 otherwise.
;; add if operator, with condition, then and else parts.

;; further tests:
;; [2016-10-21 17:00] typing done (10 min), now testing.
(test (interp (desugar (parse '(= 5 5)))) 1)
(test (interp (desugar (parse '(= 1 8)))) 0)
(test (interp (desugar (parse '(if 4 2 3)))) 2)
(test (interp (desugar (parse '(if 0 2 3)))) 3)
(test (interp (desugar (parse '(if (= 1 8) 2 3)))) 3)
(test (interp (desugar (parse '(* 5 (if (= 1 8) 2 3))))) 15)

|#
