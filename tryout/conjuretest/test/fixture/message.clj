(ns fixture.message
  (:use conjure.core.model.database))

(def records [
  ; Add your test data here.
  { :id 1 }])

(defn fixture [function]
  (apply insert-into :messages records)
  (function)
  (delete :messages [ "true" ]))