Clojure/lisp 'puzzel'

Trigger: xhtml data van RWS, met data als

1-level 1
2-level 2 detail
2-level 2 detail
1-level 1 nieuwe


Alles dus platgeslagen. Doel was dit in DB te zetten, met tabellen voor level 1 en level 2.
Bij doorlopen weer traditioneel imperatief opgelost, met bijhouden vorige waarden etc.
Vraag of dit ook functioneel kan.

In eerste instantie recursief, tail-recursive met accumulator?

Later kijken waar dit algemener kan?

Input par1: de lijst, welke vorm
Input par2: een functie die van een element een level maakt. Idee is dat een lager level (met een hoger nummer) onder een element
met een hoger level (lager nummer) komt te hangen.
Result: een geneste lijst.

In eerste instantie uitgaan van een nette input lijst.

De lists zijn vectors, idiomatic clojure.

Elementen input kunnen alles zijn, zolang maar level kan worden bepaald.

Elementen output: hashmap: :elt -> oorspronkelijke element.
                           :sub -> list met onderliggende elementen.
                                   ook weer met :elt en :sub (?)
                                   
                                   
dus:
input: [1 2 2 2 1 1 2 2]
dan wordt output:

[{:elt 1, :sub [{:elt 2} {:elt 2} {:elt 2}]} {:elt 1} {:elt 1 :sub [{:elt 2} {:elt 2}]}]

of geen hash-map maar gewoon lijst:

[[1 [2 2 2]] [1] [1 [2 2]]]

dan is head het hogere element en de tail de lijst met subelementen.

Maar wat krijg je met de volgende input:
[1 2 3 3 2 1 1 2 2]

[[1 [2 [3 3]] [2]] [1] [1 [2 2]]]

herkennen of je een orig element hebt of niet, maar dit is foutgevoelig, als orig bv ook een vector is.

hoe in Tcl langs te lopen:
foreach el [det_result $lst] {
  set lev1 [lindex $el 0] ; # head
  set sublist [lrange $el 1 end]
  foreach elsub $sublist {
    set lev2 [lindex $elsub 0]
    set sublist3 [lrange $elsub 1 end]: [3 3] in eerste geval, leeg in het tweede
  }
}

om het resultaat te testen: pprint doen, zelf met inspringen printen?

; acc: list of handled items, will not append on items in this list
; curr: current item, maybe new items will be appended to this one.
(defn level 
  ([l] (level l [] []))
  ([l acc curr] 
    (cond (empty? l) (conj acc curr)
          (empty? curr) (recur (rest l) acc [(first l)])
          (<= (first l) (first curr)) (recur (rest l) (conj acc curr) [(first l)])
          true (recur (rest l) acc (place-item curr (first l))))))

[[1 [2 [3 3]] [2]] [1] [1 [2 2]]]
user=> l1
[1 [2 [3 3]] [2]]
user=> (first l1)
1

[1 [2]] + 3 => [1 [2 [3]]]

; @pre: item has a level bigger than (first l)
(defn place-item [l item]
  (cond (empty? (rest l)) [(first l) [item]]
        (<= item (first (last l))) (conj l [item])
        true (conj (vec (butlast l)) (place-item (last l) item))))
        
Eigenlijk maak ik hier een tree.

met zipper functies misschien wel weer imperatief achtig?

of een seq/zip van de source, hier doorheen lopen en aanpassen? Klinkt minder handig.

zipper is conceptueel een tree + current location.

invariant is bv dat current location de last inserted item is.

; deze gaat wel uit van goede input, dus niet later een 0 terwijl je met 1 bent begonnen.
; en gaat ook uit van een input met minimaal 1 waarde.
(defn level 
  ([l] (level (rest l) (zip/down (zip/vector-zip [(first l)]))))
  ([l z] 
    (cond (empty? l) (zip/root z)
          (> (first l) (zip/node z)) (recur (rest l) (-> z (zip/insert-child (first l)) zip/down))
          (= (first l) (zip/node z)) (recur (rest l) (-> z (zip/insert-right (first l)) zip/right))
          true (recur l (-> z zip/up)))))

(zip/insert-child (zip/down (zip/vector-zip [1])) 2)

(zip/insert-child (zip/vector-zip [1]) 2)

; overal vector van maken, ook van child elements.
(defn level 
  ([l] (level (rest l) (zip/down (zip/vector-zip [[(first l)]]))))
  ([l z] 
    (cond (empty? l) (zip/root z)
          (> (first l) (first (zip/node z))) (recur (rest l) (-> z (zip/insert-child [(first l)]) zip/down))
          (= (first l) (first (zip/node z))) (recur (rest l) (-> z (zip/insert-right [(first l)]) zip/right))
          true (recur l (-> z zip/up)))))

; zelf functies maken voor zipper, met hash-map

;keys zijn :value en :children
children is een vector, value is een integer

root is ook zo'n ding met value 0

; misschien ook with-meta, net als vector-zip
(def empty-map-zip
  (zip/zipper 
    map?
    :children
    (fn [node children] (hash-map :value (:value node) :children children))
    (hash-map :value 0 :children [])))

  
(defn level 
  ([l] (level l empty-map-zip))
  ([l z] 
    (cond (empty? l) (:children (zip/root z))
          (> (first l) (:value (zip/node z))) (recur (rest l) (-> z (zip/insert-child (hash-map :value (first l) :children [])) zip/down))
          (= (first l) (:value (zip/node z))) (recur (rest l) (-> z (zip/insert-right (hash-map :value (first l) :children [])) zip/right))
          true (recur l (-> z zip/up)))))

(defn level-to-vec [lev]
  ;(println lev)
  (vec (map (fn [node] 
    (cond (empty? (:children node)) (:value node)
          true [(:value node) (level-to-vec (:children node))]))
    lev)))

; dit werkt dus, had een haakje te veel, de vector werd als functie aangeroepen, dus zonder params.
user=> ([])
java.lang.IllegalArgumentException: Wrong number of args (0) passed to: PersistentVector (NO_SOURCE_FILE:0)


