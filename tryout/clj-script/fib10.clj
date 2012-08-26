#!/bin/bash lein-exec

;; Taken from http://j.mp/IiT8UK
(def fib-seq
  ((fn rfib [a b]
    (lazy-seq (cons a (rfib b (+ a b)))))
    0 1))

(println (take 10 fib-seq))

