module Main
    where
import IO
import Random

main = do
  hSetBuffering stdin LineBuffering
  num <- randomRIO (1::Int, 100)
  putStrLn "I’m thinking of a number between 1 and 100"
  doGuessing num

doGuessing num = do
  putStrLn "Enter your guess:"
  guess <- getLine
  let guessNum = read guess
  if guessNum < num
    then do putStrLn "Too low!"
            doGuessing num
    else if read guess > num
            then do putStrLn "Too high!"
                    doGuessing num
            else do putStrLn "You Win!"

askForWords = do
  putStrLn "Please enter a word:"
  word <- getLine
  if word == ""
    then return []
    else do
      rest <- askForWords
      return (word : rest)

factorial 1 = 1
factorial n = n * factorial (n-1)
      
readNumberList = do
  putStrLn "Type a number (0 to stop):"
  strNumber <- getLine
  let number = read strNumber
  if number == 0
    then return []
    else do
      rest <- readNumberList
      return (number : rest)

putFactorials [] = do
  putStrLn "The end"
  
putFactorials (x:xs) = do
  putStrLn ((show x) ++ " factorial is " ++ (show (factorial x)))
  putFactorials xs
      
calcNumberList = do
  list <- readNumberList
  putStrLn ("The sum is " ++ show (foldr (+) 0 list))
  putStrLn ("The product is " ++ show (foldr (*) 1 list))
  putFactorials list
  
