;; ns-decl follows:
(ns mediaweb.models.wedstrijd
  (:use korma.db korma.core)
  (:require [clojure.string :as string]
            [clj-time.core :as t]
            [clj-time.coerce :as tc]
            [clj-time.format :as tf]
            [libndv.core :as h]
            [libndv.coerce :refer [to-key]]
            [libndv.crud :refer [def-model-crud]]
            [libndv.datetime :refer [as-date-string date-between format-time]]
            [mediaweb.models.entities :refer :all]
            [mediaweb.models.persoon :as mp]
            [mediaweb.models.team :refer [team-wedstrijden]]))

(defn all-wedstrijden []
  (select wedstrijd))

(defn thuis-wedstrijden []
  (select wedstrijd
          (fields :id :naam :datumtijd :opmerkingen)
          (where {:lokatie "thuis"})
          (with scheids (fields [:id :sid] :status)
                (with persoon (fields [:naam :pnaam] [:id :pid])))
          (order :datumtijd)))

(defn wedstrijd-by-id [id]
  (first
   (select wedstrijd
           (where {:id (to-key id)})
           (with scheids (fields [:id :sid] :status)
                 (with persoon (fields [:naam :pnaam] [:id :pid]))))))

(defn scheids-history-by-wedstrijd [id]
  (select scheids_history
          (fields :id :opmerkingen :date_changed [:persoon2.naam :pnaam-new]
                  [:persoon2.id :pid-new])
          (with persoon
                (fields [:naam :pnaam-old] [:id :pid-old]))
          (join [persoon :persoon2] (= :persoon2.id :persoon_new))
          (where {:wedstrijd id})
          (order :date_changed)))

(defn wedstrijd-notes-update [id notes status]
  (update wedstrijd
          (set-fields {:notes notes})
          (where {:id (to-key id)})))

;; this fn is called from a view method, where only wid is known, not the wedstrijd object, so have to retrieve it here. Alternative would be to give the old pid in the URL, but this does not seem right.
(defn wedstrijd-scheids-update [wid pid notes]
  (let [w (wedstrijd-by-id wid)
        pid-old (:pid w)]
    (insert scheids_history
            (values {:wedstrijd (to-key wid)
                     :date_changed (t/now)
                     :opmerkingen notes
                     :persoon_old pid-old :persoon_new (to-key pid)})))
  (update scheids
          (set-fields {:persoon (to-key pid)})
          (where {:wedstrijd (to-key wid)})))

;; param datumtijd: clj-time/joda object ("20-5-2015 19:30")
(defn wedstrijd-datumtijd-update [id datumtijd notes]
  (update wedstrijd
          (set-fields {:datumtijd datumtijd})
          (where {:id (to-key id)}))
  (wedstrijd-scheids-update id (:id (mp/persoon-by-name "Invaller")) notes))

;; uitgangspunt: persoon zit in 1 team, team heeft op een dag maar 1 wedstrijd.
;; bij coaches hoeft dit niet zo te zijn...
;; dus evt later bij elke wedstrijd dezelfde checks doen.
(defn speelt-zelf-str [w p]
  (if-let [team-wedstrijd (->> (team-wedstrijden (:tid p))
                               (filter #(= (as-date-string (:datumtijd w))
                                           (as-date-string (:datumtijd %))))
                               first)]
    (if (= "thuis" (:lokatie team-wedstrijd))
      (if (= (format-time (:datumtijd w))
             (format-time (:datumtijd team-wedstrijd)))
        "Thuis wedstrijd op dezelfde tijd"
        "<b>Thuis wedstrijd op andere tijd</b>")
      "Uit wedstrijd")))

;; functie scheids-wedstrijden maken, die van een persoon de wedstrijden toont. Dan hier filter op gelijk aan speelt-zelf-str
(defn al-scheids-str [w p]
  (if-let [scheids-wedstrijd (->> (mp/scheids-wedstrijden (:id p))
                                  (filter #(= (as-date-string (:datumtijd w))
                                              (as-date-string (:datumtijd %))))
                                  first)]
    (if (= (format-time (:datumtijd w))
           (format-time (:datumtijd scheids-wedstrijd)))
      (if (= (:id w) (:id scheids-wedstrijd))
        "Fluit deze wedstrijd"
        "Fluit andere wedstrijd op dezelfde tijd")
      "Fluit andere wedstrijd op andere tijd")))

;; alle afwezig van persoon ophalen, filteren op eerste/laatste dag, of wedstrijd datum hierbinnen valt.
(defn afwezig-str [w p]
  (if-let [afw (->> (mp/persoon-afwezig (:id p))
                    (filter #(date-between (:datumtijd w)
                                           (:eerstedag %) (:laatstedag %)))
                    first
                    :opmerkingen)]
    (str "Afwezig: " afw)))

;; bepaal of persoon een wedstrijd zou kunnen fluiten, ivm zelf spelen, al scheids bij
;; andere wedstrijd en/of afwezig.
;; idee is notes of nil per situatie te bepalen, en deze aan elkaar te plakken.
;; TODO heb nu formatting (<b>) in models, is natuurlijk niet de bedoeling.
;; Dit stuk mss in views neerzetten, of de lijst wel in models, maar dan formatteren in views.
(defn wedstrijd-persoon-notes [w p]
  (let [sp (speelt-zelf-str w p)
        scheids (al-scheids-str w p)
        afw (afwezig-str w p)
        l (remove string/blank? [sp scheids afw])]
    (if (seq l)
      (string/join "<br/>" l)
      "<b>Optie</b>")))

