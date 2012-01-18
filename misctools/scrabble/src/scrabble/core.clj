(ns scrabble.core)

; first just some helper functions.
; do we have enough letters to form word?
; the idea is to see the word and letters as bags/multisets of letters and diff them. 
; if the result is empty, we're ok.
(defn enough-letters [word letters]
  (merge-with - (frequencies word) (frequencies letters)))
; merge-with not ok, it doesn't apply - if a letter only occurs in letters.

; some functies to query db (sqlite) for wordt/re's.
; ? does this work with sqlite, in Tcl it does.
; otherwise try the speed of re's vs the word-list-file compared to doing this with grep.

;tests
(def word (frequencies "HONDO"))
(def letters (frequencies "DNOQ"))
(def letters2 (frequencies "HONDOQ"))
user=> (use 'clj-diff.core)
nil
user=> (diff word letters)
;{:+ [[-1 [\D 1]] [2 [\O 1] [\Q 1]]], :- [0 1 3]}

(diff word letters2)
; {:+ [[3 [\Q 1]]], :- []}

(def res (diff word letters2))
 (= [] (:- res))
;true

(defn enough-letters [word letters]
  (= [] (:- (diff (frequencies word) (frequencies letters)))))

user=> (enough-letters "HONDO" "QOONDH")
false
user=> (enough-letters "HONDO" "HONDOQ")
true
;dus nog niet goed.


user=> (diff (f "HONDO") (f "QOONDH"))
{:+ [[0 [\Q 1]] [3 [\H 1]]], :- [0]}
;idd is de :- niet leeg.

;diff beschouwd params als sequences, dus met ordering.
(def f (comp frequencies sort))

(diff (f "HONDO") (f "QOONDH"))
{:+ [[3 [\Q 1]]], :- []}

(defn enough-letters [word letters]
  (= [] (:- (diff (-> word frequencies sort) (-> letters frequencies sort)))))

user=> (enough-letters "HOND" "DNOHHQ")
false

(diff (f "HOND") (f "DNOHHQ"))
;{:+ [[1 [\H 2]] [3 [\Q 1]]], :- [1]}
;en idd is de :- weer niet leeg.
(f "HOND")

(f "DNOHHQ")
user=> (f "HOND")
{\D 1, \H 1, \N 1, \O 1}
user=> (f "DNOHHQ")
{\D 1, \H 2, \N 1, \O 1, \Q 1}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;andere lib
(use 'com.georgejahad.difform)
(difform { 1 2 3 4 5 6} { 5 6 1 2 3 7})
   {1 2, 3
 - 4
 + 7
   , 5 6}
   
(difform (f "HONDO") (f "QOONDH"))   
   {\D 1, \H 1, \N 1, \O 2
 + , \Q 1
   }

(difform (f "HONDO") (f "HONDOQ"))   
   {\D 1, \H 1, \N 1, \O 2
 + , \Q 1
   }
; komt iig hetzelfde uit, hoopgevend.
(difform (f "HONDO") (f "HNDOQ"))
   {\D 1, \H 1, \N 1, \O
 - 2
 + 1, \Q 1
   }

(def res (difform (f "AB") (f "BC")))   
   {\
 - A
 + B
   1, \
 - B
 + C
   1}

;wil dus dat A ergens staat.
res
;nil
; da's ook niet goed.

;;;;;;;;;;;;;;;;;;;;;
; toch zelf doen met reduce etc

(f "DNOHHQ")
user=> (f "HOND")
{\D 1, \H 1, \N 1, \O 1}
user=> (f "DNOHHQ")
{\D 1, \H 2, \N 1, \O 1, \Q 1}

; sort is ook niet direct nodig.
;(defn frequencies
;  "Returns a map from distinct items in coll to the number of times
;  they appear."


(defn enough-letters [word letters]
  (let [fword    (frequencies word)
        fletters (frequencies letters)]
    (not-any? pos? 
      (map (fn [[letter cnt]]
            (- cnt (fletters letter 0))) fword)))) 
        
(defn enough-letters [word letters]
  (let [fword    (frequencies word)
        fletters (frequencies letters)]
     (->> fword
          (map (fn [[letter cnt]]
            (- cnt (fletters letter 0))))
          (not-any? pos?))))
        
(defn have-letters? [word letters]
  (let [fletters (frequencies letters)]
     (->> word
          frequencies                       ; frequency map of letters in word
          (map (fn [[letter cnt]]           ; sequencing a map yields vectors [key value]
            (- cnt (fletters letter 0))))   ; #times letter appears in word -/- #times in letters
          (not-any? pos?))))                ; a positive value means a letter is in word, but not in letters.

; wel aardig, maar doe nu wel zelf een map en zoeken van de letter in fletters.
; de merge-with was ook veelbelovend, maar past functie niet toe op items die alleen in de 2e voorkomen.
; deze er eerst vanaf halen?
; of een merge-with met +, en eerst zorgen dat de frequencies van letters negatief worden!
; kan dit met een map? wordt het resultaat dan ook weer map?


(have-letters? "HOND" "HOND")
;true->ok

(have-letters? "HOND" "DNOQHO")
;true->ok

(have-letters? "HONDD" "DNOQHO")
;false->ok
(have-letters? "HONDD" "DNOQDHO")
;true->ok

(f "DNOQDHO")
;{\D 2, \H 1, \N 1, \O 2, \Q 1}
(map (fn [[l c]] {l (- c)}) (f "DNOQDHO")) 
({\D -2} {\H -1} {\N -1} {\O -2} {\Q -1})

(merge-with + (f "HOND") (map (fn [[l c]] {l (- c)}) (f "DNOQDHO")))
;fout

(type (map (fn [[l c]] {l (- c)}) (f "DNOQDHO")))
;clojure.lang.LazySeq moet weer map worden.

(type (hash-map (map (fn [[l c]] {l (- c)}) (f "DNOQDHO"))))

(def s1 (map (fn [[l c]] {l (- c)}) (f "DNOQDHO")))
;seq van maps, deze samenvoegen

(apply merge s1)
; ok
(merge-with + (f "HOND") (apply merge (map (fn [[l c]] {l (- c)}) (f "DNOQDHO"))))
;{\Q -1, \D -1, \H 0, \N 0, \O -1} -> ok

(not-any? pos? (vals (merge-with + (f "HOND") (apply merge (map (fn [[l c]] {l (- c)}) (f "DNOQDHO"))))))
;true

(defn have-letters? [word letters]
  (not-any? pos? 
    (vals 
      (merge-with + (frequencies word) 
                    (apply merge 
                      (map (fn [[l c]] {l (- c)}) 
                           (frequencies letters)))))))
; werkt ook
; met -> of ->> ?
(defn have-letters? [word letters]
  (->> letters                              ; start with available letters
       frequencies                          ; map met frequentie van elke letter in letters
       (map (fn [[l c]] {l (- c)}))         ; maak frequenties negatief, result is een sequence van maps
       (apply merge)                        ; maak hier weer 1 map van.
       (merge-with + (frequencies word))    ; voeg deze samen met de (positieve) frequencies van het gezochte woord
       vals                                 ; lijst met alle frequentie-verschillen, een positieve betekent dat een letter in word niet in letters zit.
       (not-any? pos?)))                    ; alle waarden moeten 0 of negatief zijn.

; de map en hierna apply merge is niet zo mooi.

(use '[clojure.contrib.generic.functor :only (fmap)])


(fmap inc {:a 1 :b 3 :c 5})
;{:a 2, :c 6, :b 4}

(fmap - {:a 1 :b 3 :c 5})
;{:a -1, :c -5, :b -3}
;mooi!

; put letters first, so a partial function can be made and applied/filtered on a word list.
(defn have-letters1? [letters word]
  (->> letters                              ; start with available letters
       frequencies                          ; map met frequentie van elke letter in letters
       (fmap -)                             ; maak frequenties negatief, fmap is een functor, zie haskell.
       (merge-with + (frequencies word))    ; voeg deze samen met de (positieve) frequencies van het gezochte woord
       vals                                 ; lijst met alle frequentie-verschillen, een positieve betekent dat een letter in word niet in letters zit.
       (not-any? pos?)))                    ; alle waarden moeten 0 of negatief zijn.



(have-letters? "HOND" "HOND")
;true->ok

(have-letters? "HOND" "DNOQHO")
;true->ok

(have-letters? "HONDD" "DNOQHO")
;false->ok
(have-letters? "HONDD" "DNOQDHO")
;true->ok

;;;;;;;;;;;;;;;;;;;;;;;;
; sowpods lezen
;;;;;;;;;;;;;;;;;;;;;;;;
(use '[clojure.java.io :only (reader)])

(defn get-lines [filename]
  (with-open [rdr (reader filename)]
    (doall (line-seq rdr))))

(def sp (get-lines "/media/nas/media/Talen/Dictionaries/sowpods.txt"))

(take 5 sp)
;IOException Stream closed  java.io.BufferedReader.ensureOpen (BufferedReader.java:97)

; om te testen even zonder with-open
(def rdr (reader "/media/nas/media/Talen/Dictionaries/sowpods.txt"))
(def sp (line-seq rdr))

 (take 10 sp)
("AA" "AAH" "AAHED" "AAHING" "AAHS" "AAL" "AALII" "AALIIS" "AALS" "AARDVARK")

(count sp)
; 267751 ; duurt eerste keer paar seconden

(count sp)
;instantly

(def sp (get-lines "/media/nas/media/Talen/Dictionaries/sowpods.txt"))
#'user/sp
user=> (count sp)
267751
(take 10 sp)
;doet het ook

; regexp:
(defn find-re [re l]
  (filter (partial re-seq re) l))

(find-re #"AARD" sp)
;("AARDVARK" "AARDVARKS" "AARDWOLF" "AARDWOLVES")

(find-re #"^T[ABCDE]{3,3}.{0,2}$" sp)
;("TABARD" "TABBED" "TABBIS" "TABBY" "TABEFY" "TABER" "TABERD" "TABERS" "TABES" "TACAN" "TACANS" "TACE" "TACES" "TACET" "TACETS" "TADDIE" "TAED" "TEABOX" "TEACH" "TEACUP" "TEAD" "TEADE" "TEADES" "TEADS" "TEAED" "TEBBAD" "TEDDED" "TEDDER" "TEDDIE" "TEDDY" "TEED")

(filter (partial have-letters? "ABCDET") (find-re #"^T.{3}$" sp))
;("TACE" "TAED" "TEAD")


user=> (have-letters? (concat "ABCDE" "T") "TAED")
true
user=> (have-letters? (concat "ABCDE" "T") "TAEDE")
false

user=> (re-seq #"[A-Z]" "..A..T..")
("A" "T")


(defn find-words 
  "Find words in word list (wl) that match pattern and only use letters in let
   pat is a regex like ...T.{1,3}, but given as a string, not as a #\"regexp\""
  [pat lt wl]
  (->> wl
       (find-re (re-pattern pat))
       (filter (partial have-letters? (concat lt (re-seq #"[A-Z]" pat))))))

(find-words "^T...$" "ABCDE" sp)         

(find-words "^T...$" "ABCDE" sp)
()
user=> (find-words "^T...$" "ABCDET" sp)
("TACE" "TAED" "TEAD")


(apply str "ABCDE" (re-seq #"[A-Z]" "^T...$"))
;"ABCDET"

(defn find-words 
  "Find words in word list (wl) that match pattern and only use letters in let
   pat is a regex like ...T.{1,3}, but given as a string, not as a #\"regexp\""
  [pat lt wl]
  (->> wl
       (find-re (re-pattern pat))
       (filter (partial have-letters? (apply str lt (re-seq #"[A-Z]" pat))))))

user=> (find-words "^T...$" "ABCDE" sp) 
;("TACE" "TAED" "TEAD")

; ^ en $ eigenlijk wel standaard.

; concreet vb
(find-words "^AB.{2,4}$" "LGTRAOU" sp)

; ok, werkt wel.

; nu ook een blanco, dus deze ook met have-letters? doen

(defn have-letters? 
  "Find out if there are enough letters to make word. A space in letters denotes a blank"
  [letters word]
  (->> letters                                ; start with available letters
       frequencies                            ; map met frequentie van elke letter in letters
       (fmap -)                               ; maak frequenties negatief, fmap is een functor, zie haskell.
       (merge-with + (frequencies word))      ; voeg deze samen met de (positieve) frequencies van het gezochte woord
       vals                                   ; lijst met alle frequentie-verschillen, een positieve betekent dat een letter in word niet in letters zit.
       (filter pos?)                          ; keep positive values
       (apply +)                              ; and sum these
       (>= (count (re-seq #" " letters)))))   ; and check if we have enough blanks for the not found letters 

(have-letters? "AAPJE" "AEPJQX ")
; false, niet terecht.
(have-letters? "AAPJE" "AEPJQXA")
(have-letters1? "AAPJE" "AEPJQXA")
; false, want moet eerst de letters doen.
(have-letters1? "AEPJQXA" "AAPJE")
(have-letters? "AEPQX " "AAPJE")
(have-letters? "AEPQX  " "AAPJE")
; allemaal goed.

(find-words "." "LRUIOV " sp)
; kan lang duren, 21:01 gestart, 21:02 klaar, dus valt nog mee.

; alleen woorden van 6 of 7 letters
(find-words "^.{6,7}$" "LRUIOV " sp)
; wel woorden van 6, niet van 7 letters.

(find-words "^.{6,7}E$" "LRUIOV " sp)
("OUTLIVE" "OVERLIE" "RIVULOSE" "ROUILLE" "SOILURE" "VARIOLE" "VIRGULE" "VOITURE")
;mooi, maar de laatste voor de E moet met een W te combineren zijn, en dat lukt niet.


;ideeen over verder zoeken, met horizontaal/verticaal.
;alleen letters neerleggen in dezelfde rij of kolom, die dan ook 1 woord vormen, niet mee.
;bv bekijk kolom 3. Bekijk eerst per cell wat de restricties zijn, sowieso eerst of dit al aansluit,
;als de meest linker gevulde kolom 5 is, dan kun je 3 wel overslaan, en beginnen met 4.
;restrictie: al ingevulde letter, bij blanco: zijn er horizontale restricties? zoek links en rechts
;naar einde van ingevulde letters. Voor elk van deze horizontale dingen zoeken naar mogelijkheden,
;rekening houden met eigen letters (later ook sowieso, om met tegenstander rekening te houden)
;ook later pas rekening houden met 2w waardes etc.
;hiermee krijg je dan een patroon, bv: .....[AB].T... dan wel: staat de T er al, of is dit de enige die past?
;met dit pattern heb je 2 'ankers', waarvan je iig 1 moet gebruiken. Per anker dan een nieuwe regexp maken:
;afhankelijk of je een blanco hebt, kun je de puntjes hieronder vervangen door [<letters>]
;AB: .{0,7}[AB](.(T.{0,7})?)?
;T: net andersom, nesting waarschijnlijk ook.
;mss handig eerst een FSM te maken, deze dan om te zetten naar een RE? in RE lib waarsch weer net andersom.
;als bovenstaande erg lastig is, dan eerst simpeler: per anker weer: bepaal #ankers boven en onder. Maak RE
;voor elk van de mogelijke combi's, bv 2 erboven, 1 eronder, dan alle combi's zijn 0-2 erboven, en 0-1 eronder, voor
;een totaal van 3x2 is 6 RE's. Een anker kan ook uit meer dan 1 letter bestaan, ankers worden altijd gescheiden door
;spatie? Toch weer onderscheid tussen al geplaatse letters en mogelijk te plaatsen. Voorbeelden, waarbij alles niet
;in [] betekent dat letter er al staat:
;...T[AB]..... mogelijkheden: 1) alles eindigend op een T 2) T[AB].*
; ...T.[AB].... opties: 1) alles op een T; 2) T. 3) T.[AB] 4) T.[AB].* dus RE steeds uitbreiden met anker of een groep?
; ..T..[AB].. opties: 1) alles op T; 2) ..T.{1,2} 3) ..T..[AB] 4) ..T..[AB].{1,7}
; ..T[AB][CD]... opties: 1) alles op T 2) ..T[AB] 3) ..T[AB][CD] 4)..T[AB][CD].{1,7}
;toch moet hiermee wel wat te doen zijn om het in 1 RE te krijgen, juist met een LISP.
