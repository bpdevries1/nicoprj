(ns scrabble2.core
  (:gen-class)
  (:use [clojure.java.io :only (reader writer)]
        [clojure.contrib.generic.functor :only (fmap)])
        ;[clojure.contrib.io :only (write-lines)])
  (:require [clojure.zip :as zip]))

