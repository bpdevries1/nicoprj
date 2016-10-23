#lang plai-typed

;; [2016-10-21 18:57] of deze ter vervanging van ArithC.
;; idd melding dat numC nu dubbel is.
;; [2016-10-21 19:00] Deze manier van definieren lijkt wel ok, vergelijkbaar met Grammar.
;;   desugar en interp ook wel ok, alleen parse nog vrij omslachtig.
;; [2016-10-22 20:58] application heeft 2 varianten: een die gewoon een functie naam
;; gebruikt, en een die een inplace functiedef (soort lambda) gebruikt. Kan dan bv
;; app1C en app2C gebruiken, of een subtype die je verder weer met een define-type
;; maakt.
(define-type ExprC
  [numC (n : number)]
  [idC (s : symbol)]
  #;[appC (fun : symbol) (arg : ExprC)]
  [appC (fun : ExprC) (arg : ExprC)] ; maar fun is dus niet een willekeurige ExprC.
  [plusC (l : ExprC) (r : ExprC)]
  [multC (l : ExprC) (r : ExprC)]
  [eqC (l : ExprC) (r : ExprC)]
  [ifC (c : ExprC) (t : ExprC) (e : ExprC)]
  ;; [2016-10-22 20:56] function type take 1, hier zit nog een name in.
  [fdC (name : symbol) (arg : symbol) (body : ExprC)]
  )

;;(appC 'double (numC 5))

;; [2016-10-21 18:52] Add functions, first with one parameter.
;; [2016-10-22 21:03] deze voorlopig weg.
#;(define-type FunDefC
    [fdC (name : symbol) (arg : symbol) (body : ExprC)])


(define-type-alias Env (listof Binding))
(define mt-env empty)
(define extend-env cons)

(define-type Value
  [numV (n : number)]
  [funV (name : symbol) (arg : symbol) (body : ExprC)])

;; (fdC 'double 'x (plusC (idC 'x) (idC 'x)))
(define-type Binding
  [bind (name : symbol) (val : Value)])


;; [2016-10-22 21:09] deze inmiddels beetje oud voor Surface expression. Weg?
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
;; [2016-10-22 21:04] deze voorlopig ook niet nodig.
#;(define (get-fundef [n : symbol] [fds : (listof FunDefC)]) : FunDefC
    (cond
      [(empty? fds) (error 'get-fundef "reference to undefined function")]
      [(cons? fds) (cond
                     [(equal? n (fdC-name (first fds))) (first fds)]
                     [else (get-fundef n (rest fds))])]))

;; [2016-10-22 19:50] nieuwe interp met gebruik van Env (=listof Binding)
;; [2016-10-22 21:11] inmiddels de oude, hier klopt nu weinig meer van.
#;(define (interp [expr : ExprC] [env : Env]) : number
    (type-case ExprC expr
      [numC (n) n]
      [idC (n) (lookup n env)]
      [fdC (n a b) expr] ; gaat voorlopig niet goed, je moet een number opleveren.
      ;; deferral of substitution betekent hier in de env zetten.
      ;; [2016-10-22 21:07] willen we deze nog ondersteunen? of alleen in place definitions?
      [appC (f a) (local ([define fd (get-fundef f fds)])
                    ; (interp <body> (extend-env (bind <arg> < a of (interp a)>)) fds
                    ; a is ExprC, dus ook hier interp nodig.
                    ; bij functie applicatie weer met empty env beginnen.
                    (interp (fdC-body fd)
                            (extend-env (bind (fdC-arg fd)
                                              (interp a env fds))
                                        mt-env)
                            fds))]
      
      [plusC (l r) (+ (interp l env fds) (interp r env fds))]
      [multC (l r) (* (interp l env fds) (interp r env fds))]
      [eqC (l r) (if (= (interp l env fds) (interp r env fds)) 1 0)]
      [ifC (c t e) (if (= 0 (interp c env fds)) (interp e env fds) (interp t env fds))]))

;; [2016-10-22 21:11] start van een nieuwe, die met in-place function defs en values
;; om kan gaan.
;; [2016-10-22 21:35] wel weer forward ref naar de desugar-er.
(define (interp [expr : ExprC] [env : Env]) : Value
  (type-case ExprC expr
    [numC (n) (numV n)]
    [idC (n) (lookup n env)]
    ; check dat f een functie-def is: met geneste type-case weer:
    ; wel opmerking dat je ofwel de f checkt op zijnde een fdC, ofwel het resultaat
    ; is een funV. Laatste waarsch beter, flexibeler. Vraag of je een situatie kunt
    ; verzinnen waarbij het ene wel waar is, maar het andere niet. Kan dus 2 kanten op.
    ; denk dat een fdC wel altijd een funV oplevert (zie onder), dus kan een funV ook
    ; anders worden opgeleverd? Iets met een fdC doorgeven als param naar een functie?
    #;[appC (f a) (local ([define fd f])
                    (interp (fdC-body fd)
                            (extend-env (bind (fdC-arg fd)
                                              (interp a env))
                                        mt-env)))]
    ; take 2 hieronder: geen expliciete check, maar zal falen als funV-body niet kunt gebruiken.
    [appC (f a) (local ([define fd (interp f env)])
                  (interp (funV-body fd)
                          (extend-env (bind (funV-arg fd)
                                            (interp a env))
                                      mt-env)))]
    
    ; (numV (+ (interp l env) (interp r env))) werkt niet, want je moet Value naar number omzetten.
    [plusC (l r) (num+ (interp l env) (interp r env))]
    [multC (l r) (num* (interp l env) (interp r env))]
    
    ;; eqC en ifC er ook bij. Blijft op zich goede oefening.
    ;; [2016-10-22 21:14] hieronder waarschijnlijk de function definition.
    [fdC (n a b) (funV n a b)]
    [else (error 'interp "if and = not supported now")]
    ))

;; is return type hier een numV of een Value? Vermoed toch een Value.
;; [2016-10-22 21:21] dit is eigen Impl, kijk wat gegeven wordt.
#;(define (num+ (l : Value) (r : Value)) : numV
    (if (and (numV? l) (numV? r))
        (+ (numV-n l) (numV-n r))
        (error 'num+ "Cannot add non-numbers")))

;; blijkbaar vindt schrijver cond duidelijker dan if, en zit wat in.
(define (num+ [l : Value] [r : Value]) : Value
  (cond
    [(and (numV? l) (numV? r))
     (numV (+ (numV-n l) (numV-n r)))]
    [else
     (error 'num+ "one argument was not a number")]))

;; [2016-10-22 21:24] deze lijkt veel op num+, dus zou ook met hulp functie of macro moeten kunnen.
(define (num* [l : Value] [r : Value]) : Value
  (cond
    [(and (numV? l) (numV? r))
     (numV (* (numV-n l) (numV-n r)))]
    [else
     (error 'num* "one argument was not a number")]))

;; [2016-10-22 20:08] deze zelf bedacht, nog testen dus. Straks eerst compleet,
;; met de testcases. Mocht er iets fout gaan, dan losse testen maken eerst.
;; ik zocht net case, maar had cond moeten zoeken.
;; had equal? maar symbol=? is specifieker.
(define (lookup (n : symbol) (env : Env)) : Value
  (if (empty? env)
      (error 'lookup "Cannot find symbol in env")
      (if (symbol=? n (bind-name (first env)))
          (bind-val (first env))
          (lookup n (rest env)))))

;; [2016-10-22 20:21] de officele hieronder:
#;(define (lookup [for : symbol] [env : Env]) : number
    (cond
      [(empty? env) (error 'lookup "name not found")]
      [else (cond
              [(symbol=? for (bind-name (first env)))
               (bind-val (first env))]
              [else (lookup for (rest env))])]))


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
;; [2016-10-22 21:03] subst voorlopig niet meer gebruikt.
#;(define (subst [what : number] [for : symbol] [in : ExprC]) : ExprC
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

;; [2016-10-23 11:49] doet het voorlopig niet, ook geen tijd aan besteed in boek laatste hoofdstukken.
#;(define (desugar [s : ExprS]) : ExprC
  (type-case ExprS s ; waarom beide nodig? s om aan te geven over welke param het gaat. ArithS: dat je 'em op dit niveau in de class-tree wilt bekijken.
    [numS (n) (numC n)]
    [plusS (l r) (plusC (desugar l) (desugar r))]
    [multS (l r) (multC (desugar l) (desugar r))]
    [bminusS (l r) (plusC (desugar l) (multC (numC -1) (desugar r)))]
    [uminusS (l) (multC (numC -1) (desugar l))]
    [eqS (l r) (eqC (desugar l) (desugar r))]
    [ifS (c t e) (ifC (desugar c) (desugar t) (desugar e))]))

;; [2016-10-23 11:46] Tests with inline function def version:
(test (interp (plusC (numC 10) (appC (fdC 'const5 '_ (numC 5)) (numC 10)))
              mt-env)
      (numV 15))

;; [2016-10-23 11:50] en zo test je dus of een expressie een exceptie oplevert:
(test/exn (interp (appC (fdC 'f1 'x (appC (fdC 'f2 'y (plusC (idC 'x) (idC 'y)))
                                          (numC 4)))
                        (numC 3))
                  mt-env)
          "lookup: Cannot find symbol in env")


