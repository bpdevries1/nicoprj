-- main = read list of directories and their sizes
--       decide how to fit them on CD-Rs
--       print solution
       
-- Taken from 'cd-fit-1-1.hs'
module Main where
 
main = do putStrLn "Who are you?"
          name <- getLine
          putStrLn ("Hello " ++ name)
          putStrLn "What's your fav color?"
          color <- getLine
          putStrLn ("So it is " ++ color)
          -- compute solution and print it        
