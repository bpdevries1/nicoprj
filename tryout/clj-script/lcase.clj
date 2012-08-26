#!/bin/bash lein-exec

(loop []
  (let [c (.read *in*)]
    (when (>= c 0)
      (if (and (>= c (int \A)) (<= c (int \Z)))
        (print (Character/toLowerCase (char c)))
        (print (char c)))
      (recur))))

