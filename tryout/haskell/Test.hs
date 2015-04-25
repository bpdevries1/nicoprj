module Test
    where
x = 5
y = (6, "Hello")
z = x * fst y

square (x :: Int)  = x * x

intsquare :: Int -> Int
-- intsquare :: Double -> Double
intsquare x = x * x

signum x =
    if x < 0
      then -1
      else if x > 0
        then 1
        else 0

f 0 = 1
f 1 = 5
f 2 = 2
f _ = -1

g = square . f

roots a b c =
    let det = sqrt (b*b - 4*a*c)
        twice_a = 2*a
    in ((-b + det) / twice_a,
         (-b - det) / twice_a)

factorial 1 = 1
factorial n = n * factorial (n-1)

exponent a 1 = a
exponent a b = a * Test.exponent a (b-1)

my_length [] = 0
my_length (x:xs) = 1 + my_length xs

my_filter p [] = []
my_filter p (x:xs) =
  if p x
    then x : my_filter p xs
    else my_filter p xs

my_map f [] = []
my_map f (x:xs) = (f x):(map f xs)

fib 1 = 1
fib 2 = 1
fib n = (fib (n-1)) + (fib (n-2))

mult a 1 = a
mult a b = a + mult a (b-1) 

data Pair a b = Pair a b deriving Show
pairFst (Pair x y) = x
pairSnd (Pair x y) = y

data Triple a b c = Triple a b c deriving Show
tripleFst (Triple a b c) = a
tripleSnd (Triple a b c) = b
tripleThr (Triple a b c) = c

-- eerste a en b zijn types die hierin worden gebruikt. Volgende a a b b zijn params voor constructor
data Quadruple a b = Quadruple a a b b deriving Show

-- bij def van type functie weer uitgaan van type defs, en niet van constructor.
firstTwo :: (Quadruple a b) -> [a]
lastTwo  :: (Quadruple a b) -> [b]

-- bij def van functoe en pattern matching wel weer alle params.
firstTwo (Quadruple a b c d) = [a,b]
lastTwo (Quadruple a b c d) = [c,d]

makepair :: a -> (b,c)  -> (a, (b,c))
makepair a b = (a,b)

firstElement :: [a] -> Maybe a
firstElement []     = Nothing
firstElement (x:xs) = Just x

findElement :: (a -> Bool) -> [a] -> Maybe a
findElement p [] = Nothing
findElement p (x:xs) =
    if p x then Just x
    else findElement p xs

    
data Tuple a b c d = Tuple4 a b c d 
                   | Tuple3 a b c
                   | Tuple2 a b
                   | Tuple1 a
                   deriving Show
                   
tuple1 :: (Tuple a b c d) -> Maybe a
tuple2 :: (Tuple a b c d) -> Maybe b
tuple3 :: (Tuple a b c d) -> Maybe c
tuple4 :: (Tuple a b c d) -> Maybe d

tuple1 (Tuple1 a) = Just a
tuple1 (Tuple2 a b) = Just a
tuple1 (Tuple3 a b c) = Just a
tuple1 (Tuple4 a b c d) = Just a

tuple2 (Tuple1 a) = Nothing
tuple2 (Tuple2 a b) = Just b
tuple2 (Tuple3 a b c) = Just b
tuple2 (Tuple4 a b c d) = Just b

tuple3 (Tuple1 a) = Nothing
tuple3 (Tuple2 a b) = Nothing
tuple3 (Tuple3 a b c) = Just c
tuple3 (Tuple4 a b c d) = Just c

tuple4 (Tuple1 a) = Nothing
tuple4 (Tuple2 a b) = Nothing
tuple4 (Tuple3 a b c) = Nothing 
tuple4 (Tuple4 a b c d) = Just d

tupleContents :: (Tuple a b c d) -> Either a (Either (a,b) (Either (a,b,c) (a,b,c,d)))
tupleContents (Tuple1 a) = Left a
tupleContents (Tuple2 a b) = Right (Left (a,b))
-- tupleContents (Tuple2 a b) = Left (Right (a,b))
tupleContents (Tuple3 a b c) = Right(Right (Left (a,b,c)))
tupleContents (Tuple4 a b c d) = Right(Right (Right (a,b,c,d)))
-- of met een Either4 type?
-- de oplossing in PDF is symmetrisch, maar komt op hetzelfde neer.


-- TODO
{-

15-3-2009:
Probeer hier dus een LISP like list structuur te maken, door foldr op makepair en leeg pair te maken.
Alleen nu soort recursieve, infinite definitie.

*Test> let makepair = (\x y -> (x,y))
*Test> makepair 1,2
<interactive>:1:10: parse error on input `,'
*Test> makepair 1 2 
(1,2)
*Test> makepair 0 0
(0,0)
*Test> makepair 3 (0,0)
(3,(0,0))
*Test> let mp1 = makepair 3 (0,0)
*Test> let mp2 = makepair 2 mp1
*Test> let mp3 = makepair 1 mp2
*Test> mp3
(1,(2,(3,(0,0))))
*Test> :t makepair
makepair :: forall t t1. t -> t1 -> (t, t1)
*Test> :t foldr
foldr :: forall a b. (a -> b -> b) -> b -> [a] -> b
*Test> :t (0,0)
(0,0) :: forall t t1. (Num t1, Num t) => (t, t1)
*Test> foldr makepair (0,0) [1,2,3]

<interactive>:1:6:
    Occurs check: cannot construct the infinite type: b = (a, b)
      Expected type: a -> b -> b
      Inferred type: a -> b -> (a, b)
    In the first argument of `foldr', namely `makepair'
    In the expression: foldr makepair (0, 0) [1, 2, 3]
*Test> :t foldr makepair (0,0) [1,2,3]

<interactive>:1:6:
    Occurs check: cannot construct the infinite type: b = (a, b)
      Expected type: a -> b -> b
      Inferred type: a -> b -> (a, b)
    In the first argument of `foldr', namely `makepair'
*Test> 
-}

