; deze wordt veel gebruikt.
(defn atom? [x]
  (and (not (list? x))
       (not (nil? x))))
       
(defn sub1 [x]
   (- x 1))

(def add1 inc)

; zero? bestaat al

(def car first)

(def cdr rest)

; zowel true opleveren bij nil als bij ()
(defn null? [x]
  (or (nil? x)
    (= x '())))

; quote werkt al

(def eq? =)

; H2
; lat? check lijst of alle items atoms zijn.
; is volgens mij wel std, kan nu niet vinden.
; met apply, and en map zou het ook moeten kunnen, maar and is een macro.
; voorlopig recursief
(defn lat? [x]
  (if (null? x) true
    (and (atom? (car x)) (lat? (cdr x)))))

; beter, want tail recursive
(defn lat? [x]
  (if (null? x) true
    (if (atom? (car x)) (lat? (cdr x)) false)))

(defn member? [a l]
  (if (null? l) 
    false
    (if (= a (car l)) true (member? a (cdr l)))))

; herschrijven met or
(defn member? [a l]
  (if (null? l) 
    false
    (or (= a (car l)) (member? a (cdr l)))))

; en met recur
(defn member? [a l]
  (if (empty? l) 
    false
    (or (= a (first l)) (recur a (rest l)))))

;rember: remove a member, eerst niet tail-recursive. a member, dus max 1 removen.
(defn rember [a l]
  (if (null? l) l 
    (if (= a (car l)) (cdr l)
      (cons (car l) (rember a (cdr l))))))

;tail recursive, dan acc nodig.
; wel 2x concat nodig, duur?
(defn rember1 [a l acc]
  (if (null? l) acc 
    (if (= a (car l)) (concat acc (cdr l))
       (recur a (cdr l) (concat acc (cons (car l) '()))))))

(defn rember [a l] (rember1 a l '()))

(defn firsts [l]
  (map first l))

; add new right after old in lat; if no old in lat, then just lat.
(defn insertR [new old lat]
  (if (null? lat) lat
    (if (= old (car lat))
      (cons old (cons new (cdr lat)))
      (cons (car lat) (insertR new old (cdr lat))))))

;insertL: zet new item to the left of old.
(defn insertL [new old lat]
  (if (null? lat) lat
    (if (= old (car lat))
      (cons new lat)
      (cons (car lat) (insertL new old (cdr lat))))))

;subst vervang eerste old door new in lat
(defn subst [new old lat]
  (if (null? lat) lat
    (if (= old (car lat))
      (cons new (cdr lat))
      (cons (car lat) (subst new old (cdr lat))))))

(defn subst2 [new o1 o2 lat]
  (if (null? lat) lat
    (if (or (= o1 (car lat)) (= o2 (car lat)))
      (cons new (cdr lat))
      (cons (car lat) (subst2 new o1 o2 (cdr lat))))))

;multirember: remove all occurences of an item in list
;met filter
(defn multirember [a lat]
  (filter (fn [x] (not (= x a))) lat))

;met recursie
(defn multirember [a lat]
  (if (null? lat)
    lat
    (if (= a (car lat))
      (multirember a (cdr lat))
      (cons (car lat) (multirember a (cdr lat))))))

;multiinsertR
; add new right after old in lat; if no old in lat, then just lat.
(defn multiinsertR [new old lat]
  (if (null? lat) lat
    (if (= old (car lat))
      (cons old (cons new (multiinsertR new old (cdr lat))))
      (cons (car lat) (multiinsertR new old (cdr lat))))))

;;; Hoofdstuk 5 stars
; (rember* a l) => (((tomato)) ((bean)) (and ((flying))))
; als a is sauce en l is (((tomato sauce)) ((bean) sauce) (and ((flying)) sauce))
(defn rember* [a l]
  (cond 
    (empty? l) (list)
    (list? (first l)) (cons (rember* a (first l)) (rember* a (rest l)))
    ; lijst niet leeg, eerste el geen list, dan eerste is atom, check op a
    (= a (first l)) (rember* a (rest l))
    ; eerst is atom maar geen a, bewaren en verder met rest
    true (cons (first l) (rember* a (rest l)))))

; (insertR* 'roast 'chuck l) => ((how much (wood)) could ((a (wood) chuck roast)) 
;      (((chuck roast))) (if (a) ((wood chuck roast))) could chuck roast wood)
; (def l '((how much (wood)) could ((a (wood) chuck)) (((chuck))) (if (a) ((wood chuck))) could chuck wood)) 
(defn insertR* [new old l]
  (cond 
    (empty? l) (list)
    (list? (first l)) (cons (insertR* new old (first l)) (insertR* new old (rest l)))
    ; lijst niet leeg, eerste el geen list, dan eerste is atom, check op a
    (= old (first l)) (cons old (cons new (insertR* new old (rest l))))
    ; eerst is atom maar geen old, bewaren en verder met rest
    true (cons (first l) (insertR* new old (rest l)))))

(defn intersect [set1 set2]
  (cond
    (empty? set1) (list)
    (member? (first set1) set2) 
      (cons (first set1) (intersect (rest set1) set2))
    true (intersect (rest set1) set2))) 

(defn intersectall [l-set]
  (cond 
    (empty? l-set) (list)
    (empty? (rest l-set)) (first l-set)
    true (intersect (first l-set) (intersectall (rest l-set)))))
  
; (intersectall '((a b c e) (c d b) (c e f)))  
; (intersectall '((a b c e) (c d b) (e f)))  
  
  
; richting CSP: zelf functies definieren, zien wanneer CSP echt nodig, nuttig is.
; functie die lijkt op ch.8, blz 138.
(defn split-even [lat f]
  "split list into two lists: the first has the even members, the second the odd memebers.
   after this, apply f(first, second) and return the result"
   (f (filter #(= 0 (mod % 2)) lat) (filter #(= 1 (mod % 2)) lat))) 

(split-even '(1 2 3 4 5 6) a-friend)

; voor deze met a-friend wordt true geretourneerd als het element niet voorkomt in de lijst.
(defn multirember&co [a lat col]
  "remove items a from lat, put rest in first list, and found/removed items in second. Apply (col first second)"
  (col (filter #(not (= a %)) lat) (filter #(= a %) lat)))
  
  
(defn a-friend [x y] (empty? y))

(multirember&co 'tuna '(a tuna salad dish) a-friend)
=> false

(multirember&co 'salmon '(a tuna salad dish) a-friend)
=> true

; alleen first, rest gebruiken, geen map of filter.
; lastiger 'a-friend' functie, waarbij je wel echt de lijsten moet samenstellen.
(defn more-diff [diff same]
  (- (count diff) (count same)))

(multirember&co 'tuna '(a tuna salad dish) more-diff)
=> 2, nl 3-1.

; idee is dat je functie col pas kan toepassen als je helemaal klaar bent met de lijsten.
; sowieso een hulp-functie nodig, hetzij met accumulator, hetzij een die 2 lijsten teruggeeft.

; met 2 lijsten teruggeven
; hulp functie met let en recursief gaat niet, recur kan ook niet, want niet tail recursive.

(defn mrfn [a lat]
  "retourneert 2 lijsten, eerste met diff, 2e met same items"
  (cond
    (empty? lat) (list (list) (list))
    (= a (first lat)) (list (first (mrfn a (rest lat))) (cons a (second (mrfn a (rest lat)))))
    true (list (cons (first lat) (first (mrfn a (rest lat)))) (second (mrfn a (rest lat))))
  ))

(defn multirember&co2 [a lat col]
  (apply col (mrfn a lat)))

(multirember&co2 'tuna '(a tuna salad dish) more-diff)
=> 2, dus ok, maar wel vrij omslachtig...

(multirember&co2 'tuna '(a tuna salad dish) #(list %1 %2))

; met accumulator, dan wel tail recursive, dus embedded?
(defn multirember&co3 [a lat col]
  (let [mrfn3 
    (fn [a lat acc-diff acc-same]
      (cond
        (empty? lat) (list (reverse acc-diff) (reverse acc-same))
        (= a (first lat)) (recur a (rest lat) acc-diff (cons a acc-same))
        true (recur a (rest lat) (cons (first lat) acc-diff) acc-same)))]
    (apply col (mrfn3 a lat '() '()))))

(multirember&co3 'tuna '(a tuna salad dish) #(list %1 %2))
=> ((a salad dish) (tuna))

; met accumulator best begrijpelijk, nadelen zijn hulpfunctie en reverse
; poging met collector, proberen niet steeds een nieuwe functie te retourneren?
; dit laatste gaat niet, want dan uiteindelijk col '() '(). Moet de accumulators ergens bewaren, kan niet in a en lat, dus in col.
(defn multirember&co4 [a lat col]
  (cond
    (empty? lat) (col '() '())
    (= a (first lat)) (recur a (rest lat) 
      (fn [diff same]
        (col diff (cons a same))))
    true (recur a (rest lat)
      (fn [diff same]
        (col (cons (first lat) diff) same)))))

(multirember&co4 'tuna '(a tuna salad dish) #(list %1 %2))      
=> ((a salad dish) (tuna))
; volgorde blijft dus ook goed.
; lijkt dan alleen dat je uiteindelijk een erg ingewikkelde functie hebt.
; is dit te debuggen en te printen?
; evt in tcl maken en printen? maar heb geen first class functions. Kan wel list met 2 items en hier apply op doen.

(dotrace [multirember&co4] (multirember&co4 'tuna '(a tuna salad dish) #(list %1 %2)))
=> werkt zo ook niet, ook #' nodig?

; even in clj 1.1:
(use 'clojure.contrib.trace)
(trace [multirember&co4] (multirember&co4 'tuna '(a tuna salad dish) #(list %1 %2)))
; geen nuttige info.

(defn multirember&co5 [a lat col]
  (cond
    (empty? lat) (col '() '())
    (= a (first lat)) (#'multirember&co5 a (rest lat) 
      (fn [diff same]
        (col diff (cons a same))))
    true (#'multirember&co5 a (rest lat)
      (fn [diff same]
        (col (cons (first lat) diff) same)))))

(multirember&co5 'tuna '(a tuna salad dish) #(list %1 %2))
; nog in 1.1:
(trace [multirember&co5] (multirember&co5 'tuna '(a tuna salad dish) #(list %1 %2)))
=> niet boeiend

;alsnog in 1.2:
(dotrace [multirember&co5] (multirember&co5 'tuna '(a tuna salad dish) #(list %1 %2)))
=> dan wel te zien, maar ook niet zo nuttig, inhoud van temp-functies is niet te zien.
=> even in tcl leek dus wel zinvol.

de 'b' als eerste behandeld, zit dus als diepste in een col-functie, maar komt 
uiteindelijk binnenstebuiten als eerste in de eval. 
de 'c' is de laatste, en wordt dan ge-cons-ed aan {} en wordt zo laatste element.

(use 'clojure.contrib.trace)
(defn fib[n] (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))
(dotrace [fib] (fib 3))

; met clojure 1.2 volgende nodig:
(defn fib[n] (if (< n 2) n (+ (#'fib (- n 1)) (#'fib (- n 2)))))

; iets met macro en macroexpand-1 te doen?
; of bij laatste als lijst leeg is niet eval, maar de lijst met alles, code=data spul.
(defn multirember&co6 [a lat col]
  (cond
    (empty? lat) col
    (= a (first lat)) (recur a (rest lat) 
      (fn [diff same]
        (col diff (cons a same))))
    true (recur a (rest lat)
      (fn [diff same]
        (col (cons (first lat) diff) same)))))

(def col1 (multirember&co6 'tuna '(a tuna salad dish) #(list %1 %2)))

; je zou deze geneste functie als soort fold/reduce kunnen zien.

; van http://stackoverflow.com/questions/2352020/debugging-in-clojure
(defmacro dbg[x] `(let [x# ~x] (println "dbg:" '~x "=" x#) x#))

(defn multirember&co7 [a lat col]
  (cond
    (empty? lat) (col '() '())
    (= a (first lat)) (dbg (#'multirember&co7 a (rest lat) 
      (fn [diff same]
        (col diff (cons a same)))))
    true (dbg (#'multirember&co7 a (rest lat)
      (fn [diff same]
        (col (cons (first lat) diff) same))))))

user=> (multirember&co7 'tuna '(a tuna salad dish) #(list %1 %2))
dbg: ((var multirember&co7) a (rest lat) (fn [diff same] (col (cons (first lat) diff) same))) = ((a salad dish) (tuna))
dbg: ((var multirember&co7) a (rest lat) (fn [diff same] (col (cons (first lat) diff) same))) = ((a salad dish) (tuna))
dbg: ((var multirember&co7) a (rest lat) (fn [diff same] (col diff (cons a same)))) = ((a salad dish) (tuna))
dbg: ((var multirember&co7) a (rest lat) (fn [diff same] (col (cons (first lat) diff) same))) = ((a salad dish) (tuna))
((a salad dish) (tuna))

; wel beetje zinvol, niet echt.

; idee om alleen lijst/struct op te bouwen, en buiten de functie een eval te doen.

; col input is ook een lijst?
; de (fn) aanroepen door '(fn) vervangen
(defn multirember&co8 [a lat col]
  (cond
    (empty? lat) (list col '() '())
    (= a (first lat)) (recur a (rest lat) 
      '(fn [diff same]
        (col diff (cons a same))))
    true (recur a (rest lat)
      '(fn [diff same]
        (col (cons (first lat) diff) same)))))

(multirember&co8 'tuna '(a tuna salad dish) #(list %1 %2))
=> (col (quote ()) (quote ()))

; evens-only*&co 
; multiply even numbers, sum the odd numbers, in lijst teruggeven
; 

; eerst weer met accumulator
(defn mul-col [l-evens l-odds]
  (list (apply * l-evens) (apply + l-odds)))


(defn evens-only*&co1 [l col]
  ; kan niet recurren nu, want zou op 2 punten moeten, op de first en op de rest.
  (letfn [(evens-only-acc [l acc-evens acc-odds]
    (cond (empty? l) (list acc-evens acc-odds)
          (list? (first l)) (recur (rest l) acc-evens acc-odds)
          (= 0 (mod (first l) 2)) (recur (rest l) (cons (first l) acc-evens) acc-odds)
          true (recur (rest l) acc-evens (cons (first l) acc-odds))))]
    (apply col (evens-only-acc l '() '()))))
            
; test zonder nested lists
(evens-only*&co1 '(1 2 3 4 5 6) mul-col)

; met CSP, gemakkelijker?
; (list? (first l)) (cons (rember* a (first l)) (rember* a (rest l)))
; mul-col moet misschien ook wel een geneste lijst aankunnen.
(defn evens-only*&co1 [l col]
  (cond 
    (empty? l) (col '() '())
    (list? (first l)) '(recur (rest l) 
      (fn [evens odds]
        (col (    (evens-only*&co1 (first l) (fn [evens1 odds1]  
    (= 0 (mod (first l) 2)) (recur (rest l) 
      (fn [evens odds]
        (col (cons (first l) evens) odds)))
    true (recur (rest l) 
      (fn [evens odds]
        (col evens (cons (first l) odds))))))

;         (col (evens-only*&co1 (first l) col))))
      
(defn evens-only*&co1 [l col]
  (cond 
    (empty? l) (col '() 1 0)
    (list? (first l)) (recur (first l) 
      (fn [f-evens f-prod-evens f-sum-odds]
        (evens-only*&co1 (rest l)
          (fn [r-evens r-prod-evens r-sum-odds]
            (col (cons f-evens r-evens) (* f-prod-evens r-prod-evens) (+ f-sum-odds r-sum-odds))))))
    (= 0 (mod (first l) 2)) (recur (rest l) 
      (fn [evens prod-evens sum-odds]
        (col (cons (first l) evens) (* prod-evens (first l)) sum-odds)))
    true (recur (rest l)
      (fn [evens prod-evens sum-odds]
        (col evens prod-evens (+ (first l) sum-odds))))))

; hoe lezen, bv bij first l = even: recur met rest, resultaat komt in params van nieuwe col-functie als evens, 
; prod-evens en sum-odds. Met dit resultaat roep de bestaande collector aan, aangevuld met de first waarde waar nodig.
; dan bij first l = list: eerst recur op de first, resultaat weer in params, recur vervolgens nogmaals, resultaat in andere
; params, als laatste col met deze 6 params.

; KERN: je recurred, en het resultaat staan in nieuwe-col-functie-params, hier vervolgens mee verder.

; bij dubbele recur eerst op de cdr/rest.
(defn evens-only*&co1 [l col]
  (cond 
    (empty? l) (col '() 1 0)
    (list? (first l)) (recur (rest l) 
      (fn [r-evens r-prod-evens r-sum-odds]
        (evens-only*&co1 (first l)
          (fn [f-evens f-prod-evens f-sum-odds]
            (col (cons f-evens r-evens) (* f-prod-evens r-prod-evens) (+ f-sum-odds r-sum-odds))))))
    (= 0 (mod (first l) 2)) (recur (rest l) 
      (fn [evens prod-evens sum-odds]
        (col (cons (first l) evens) (* prod-evens (first l)) sum-odds)))
    true (recur (rest l)
      (fn [evens prod-evens sum-odds]
        (col evens prod-evens (+ (first l) sum-odds))))))


(defn mul-col2 [l-evens prod-evens sum-odds]
  (list prod-evens sum-odds))

(evens-only*&co1 '(1 2 3 4 5 6) mul-col2)
(evens-only*&co1 '(1 (2 3) 4 5 6) mul-col2)

(defn mul-col3 [l-evens prod-evens sum-odds]
  (list l-evens prod-evens sum-odds))

(evens-only*&co1 '(1 (2 3) 4 5 6) mul-col3)

(evens-only*&co1 '(1 (2 3 (4 5 6)) 4 5 6 (7 (8 (9 10)))) mul-col3)

(defn the-last-friend [newl product sum]
  (cons sum (cons product newl)))

(evens-only*&co1 '(1 (2 3 (4 5 6)) 4 5 6 (7 (8 (9 10)))) the-last-friend)

(evens-only*&co1 '(1 2 3 4 5 6) the-last-friend)

; Hoofdstuk 9, again and again
; looking functie: begin bij eerste: als number? (first l), dan ga verder met zoveelste 
; element, anders check of het gelijk is aan zoekterm.
; je kunt best in een infinite loop komen, hier ook maar eens op checken.
(defn looking [a l]
  (letfn [(looking-rec [a l pos] 
    (cond
      (empty? l) false
      (number? (nth l (dec pos))) (recur a l (nth l (dec pos)))
      true (= a (nth l (dec pos)))))]
    (looking-rec a l 1)))

(looking 'caviar '(6 2 4 caviar 5 7 3))

(looking 'caviar '(6 2 grits caviar 5 7 3))
  
(looking 'caviar '(2 1))

; eentje zonder letfn en accumulator? met collector?
; misschien ook nog zonder nth?
(defn looking [a l col]
  (cond
    (empty? l) (col '())
    (number? (first l) (recur a l 
      (fn [pos]
        
        
(defn looking [a l]
  (letfn [(looking-rec [a l current] 
    (cond
      (empty? l) false
      (number? current) (recur a l (nth l (dec current)))
      true (= a current)))]
    (looking-rec a l (first l))))
        
