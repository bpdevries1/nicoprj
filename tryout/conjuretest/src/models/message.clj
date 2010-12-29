(ns models.message
  (:use conjure.core.model.base
        clj-record.boot))

(clj-record.core/init-model)

(defn
#^{ :doc "Returns the first message in the database." }
  find-first []
  (find-record ["true"]))

