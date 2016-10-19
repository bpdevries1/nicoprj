#lang racket
(require 2htdp/universe 2htdp/image)

(struct state (small big nguesses))

(define WIDTH 500)
(define HEIGHT 400)
(define TEXT-X 0)
(define TEXT-UPPER-Y 0)
(define TEXT-LOWER-Y 350)
(define TEXT-SIZE 16)
(define SIZE 36)

(define HELP-TEXT
  (text "up for larger numbers, down for smaller ones"
        TEXT-SIZE
        "blue"))

(define HELP-TEXT2
  (text "Press = when your number is guessed; q to quit."
        TEXT-SIZE
        "blue"))

(define COLOR "red")

(define MT-SC
  (place-image/align
   HELP-TEXT TEXT-X TEXT-UPPER-Y "left" "top"
   (place-image/align
    HELP-TEXT2 TEXT-X TEXT-LOWER-Y "left" "bottom"
    (empty-scene WIDTH HEIGHT))))

(define (start lower upper)
  (big-bang (state lower upper 1)
            (on-key deal-with-guess)
            (to-draw render)
            (stop-when single? render-last-scene)))

(define (deal-with-guess w key)
  (cond [(key=? key "up") (bigger w)]
        [(key=? key "down") (smaller w)]
        [(key=? key "q") (stop-with w)]
        [(key=? key "=") (stop-with w)]
        [else w]))

(define (smaller w)
  (state (state-small w)
         (max (state-small w) (sub1 (guess w)))
         (add1 (state-nguesses w))))

(define (bigger w)
  (state (min (state-big w) (add1 (guess w)))
         (state-big w)
         (add1 (state-nguesses w))))

(define (guess w)
  (quotient (+ (state-small w) (state-big w)) 2))

(define (guess-text w)
  (text (string-append (number->string (guess w)) " try#: "
                       (number->string (state-nguesses w)))
        SIZE COLOR))

#;(define (render w)
    (overlay (text (number->string (guess w)) SIZE COLOR) MT-SC))

(define (render w)
  (overlay (guess-text w) MT-SC))

(define (render-last-scene w)
  (overlay (text (string-append "End: " (number->string (guess w)))
                 SIZE COLOR) MT-SC))

(define (single? w)
  (= (state-small w) (state-big w)))

(define (d/dx fun)
  (define ∂ (/ 1 100000))
  (lambda (x)
    (/ (- (fun (+ x ∂)) (fun (- x ∂))) 2 ∂)))


(define two (d/dx (lambda (x) (* 2 x))))

(define newcos (d/dx sin))

(for ([i '(1 2 3 4 5)])
  (display i))

(define (make-lazy+ i)
  (lambda ()
    (apply + (build-list (* 500 i) values))))

(define long-big-list (build-list 5000 make-lazy+))

(define (compute-every-1000th l)
  (for/list ([thunk l] [i (in-naturals)]
                       #:when (zero? (remainder i 1000)))
    (thunk)))

;; (compute-every-1000th long-big-list)

(define (memoize suspended-c)
  (define hidden #f)
  (define run? #f)
  (lambda ()
    (cond [run? hidden]
          [else (set! hidden (suspended-c))
                (set! run? #t)
                hidden])))

(define susp (lambda () (+ 40 2)))

(define m-susp (memoize susp))

;; (define m-susp2 (memoize (lambda () (compute-every-1000th long-big-list))))

(define (memoize.v2 suspended-c)
  (define (hidden)
    (define the-value (suspended-c))
    (set! hidden (lambda () the-value))
    the-value)
  (lambda () (hidden)))

;; [2016-10-18 21:43] uitleg dat je alleen hidden moet retourneren, zoals hieronder:
(define (memoize.v3 suspended-c)
  (define (hidden)
    (define the-value (suspended-c))
    (set! hidden (lambda () the-value))
    the-value)
  hidden)

;; eigenlijk is dit gelijk aan:
#;(define (memoize.v4 suspended-c)
  (lambda ()
    (define the-value (suspended-c))
    (set! hidden (lambda () the-value))
    the-value))

;; maar niet helemaal, want hidden is nu niet meer bekend.

(define (susp2) (begin (println "abc") 12))

(define m-susp2 (memoize susp2)) ; correct, only prints "abc" once.
(define m-susp2.v2 (memoize.v2 susp2)) ; correct, only prints "abc" once.
(define m-susp2.v3 (memoize.v3 susp2)) ; incorrect, prints "abc" every time.
#;(define m-susp2.v4 (memoize.v4 susp2)) ; incorrect, prints "abc" every time.

;; deze werkt idd niet: calc wel goed, maar steeds overnieuw.
;; (define m-susp3 (memoize.v3 (lambda () (compute-every-1000th long-big-list))))

;; (define lazy+ (delay (apply + (build-list 1000000 values))))

(struct foo (bar) #:transparent)
(foo 5)
;;(foo 5)
(struct foo2 (bar) #:prefab)
(foo2 5)
;; '#s(foo 5)

