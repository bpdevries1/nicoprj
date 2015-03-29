#_(ns zap.validations
  (require [valip.core :refer [validate]]
           [valip.validations :refer [present?]]))
               
(ns zap.validations)

#_(defn valid-project? [proj]
  (validate proj
    [:name present? "name must be specified"]
    [:name (min-length 1) "name must not be blank"]))

(defn valid-project? [proj]
  nil)

(defn valid-issue? [iss]
  nil)
      
#_(defn valid-issue? [iss]
  (validate iss
    [:title present? "title must be specified"]
    [:title (min-length 1) "title must not be blank"]
    [:description present? "description must be specified"]
    [:description (min-length 1) "description must not be blank"]
    [:status (between 1 4) "status id must be between 1 and 4"]))
