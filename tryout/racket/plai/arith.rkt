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
  ;; [fdC (name : symbol) (arg : symbol) (body : ExprC)]
  ;; [2016-10-23 12:13] bovenstaande fdC niet meer geldig.
  [lamC (arg : symbol) (body : ExprC)]
  )

;; (fdC 'double 'x (plusC (idC 'x) (idC 'x)))
(define-type Binding
  [bind (name : symbol) (val : Value)])

(define-type-alias Env (listof Binding))
(define mt-env empty)
(define extend-env cons)

;; [2016-10-23 12:11] vanaf nu is het geen funV meer, maar een closure.
(define-type Value
  [numV (n : number)]
  [closV (arg : symbol) (body : ExprC) (env : Env)])



;; [2016-10-22 21:09] deze inmiddels beetje oud voor Surface expression. Weg?
(define-type ExprS
  [numS (n : number)]
  [plusS (l : ExprS) (r : ExprS)]
  [bminusS (l : ExprS) (r : ExprS)]
  [uminusS (l : ExprS)]
  [multS (l : ExprS) (r : ExprS)]
  [eqS (l : ExprS) (r : ExprS)]
  [ifS (c : ExprS) (t : ExprS) (e : ExprS)])

;; [2016-10-22 21:11] start van een nieuwe, die met in-place function defs en values
;; om kan gaan.
;; [2016-10-22 21:35] wel weer forward ref naar de desugar-er.
(define (interp [expr : ExprC] [env : Env]) : Value
  (type-case ExprC expr
    [numC (n) (numV n)]
    [idC (n) (lookup n env)]
    [lamC (a b) (closV a b env)]
    
    ; take 2 hieronder: geen expliciete check, maar zal falen als funV-body niet kunt gebruiken.
    #;[appC (f a) (local ([define fd (interp f env)])
                  (interp (funV-body fd)
                          (extend-env (bind (funV-arg fd)
                                            (interp a env))
                                      mt-env)))]
    ;; [2016-10-23 12:23] ipv laatste regel env uit closure te pakken, kun je ook orig env pakken.
    ;; wat betekent dit? -> dan gebruik je closV-env helemaal niet, dus waarom heb je 'em dan aangemaakt?
    ;; verwachting dan dat de testcase alsnog fout gaat.
    ;; [2016-10-23 22:03] testcase blijft goed gaan, ook met alleen env, wel beetje raar.
    ;; ook hier zou het dan helpen precies te kijken wat er wanneer wordt aangemaakt, vgl memoize.
    ;; env wordt hier trouwens de dynamic environment genoemd. Kan zijn dat vorige dan weer onterecht
    ;; goed gaat, met losse functie definities.
    [appC (f a) (local ([define f-value (interp f env)])
                  (interp (closV-body f-value)
                          (extend-env (bind (closV-arg f-value)
                                            (interp a env))
                                      ;env
                                      (closV-env f-value))))]
    
    ; (numV (+ (interp l env) (interp r env))) werkt niet, want je moet Value naar number omzetten.
    [plusC (l r) (num+ (interp l env) (interp r env))]
    [multC (l r) (num* (interp l env) (interp r env))]
    
    ;; [2016-10-22 21:14] hieronder waarschijnlijk de function definition.
    #;[fdC (n a b) (funV n a b)]
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
(test (interp (plusC (numC 10) (appC (lamC '_ (numC 5)) (numC 10)))
              mt-env)
      (numV 15))

;; [2016-10-23 11:50] en zo test je dus of een expressie een exceptie oplevert:
;; [2016-10-23 11:52] nu een geneste def. Met closure zou je nu kunnen zeggen dat deze wel
;;   goed zou moeten gaan.
(test (interp (appC (lamC 'x (appC (lamC 'y (plusC (idC 'x) (idC 'y)))
                                          (numC 4)))
                        (numC 3))
                  mt-env)
          (numV 7))

;; [2016-10-23 11:58] Verdere testen/probeersels vanaf par 7.2:
#;(appC (fdC 'f1 'x
           (fdC 'f2 'y
                (plusC (idC 'x) (idC 'y))))
      (numC 4))

;; [2016-10-23 12:00] deze vult nog niet de 4 in op de plek van de x. Mogelijk omdat
;; deze genest is en bij aanroep van fdC 'f2 wordt env weer gereset.
#;(interp (appC (fdC 'f1 'x
                   (fdC 'f2 'y
                        (plusC (idC 'x) (idC 'y))))
              (numC 4))
        mt-env)

;; [2016-10-23 12:02] en dan levert deze idd een fout op:
;; we zijn idd op zoek naar een closure!
#;(interp (appC (appC (fdC 'f1 'x
                         (fdC 'f2 'y
                              (plusC (idC 'x) (idC 'y))))
                    (numC 4))
              (numC 5))
        mt-env)

;; [2016-10-26 22:24] Had net een let-macro gemaakt voor clojure, nu weg. Deze werkt
;#(defmacro let2 [nm val body]
  `((fn [~nm]
      ~body)
    ~val))

;#(let2 c 12 (+ c c))

