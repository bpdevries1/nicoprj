(ns mediaweb.models.entities
  (:use korma.db korma.core)
  (:require [clojure.string :as string]
            [clj-time.core :as t]
            [clj-time.coerce :as tc]
            [clj-time.format :as tf]
            [libndv.core :as h]
            [libndv.coerce :refer [to-float to-int to-key]]))

(declare scheids)
(declare persoon)
(declare afwezig)
(declare kan_team_fluiten)
(declare costfactor)
(declare persoon_team)

;; TODO: naast prepare ook functies andere kant op: automatisch sql-date-time omzetten naar
;; clojure date-time. Maar dit lijkt niet echt nodig.
(defentity action
  (entity-fields :id :file_id :create_ts :exec_ts :exec_output :exec_stderr :exec_status
                 :action :fullpath_action :fullpath_other :notes)
  (prepare (h/updates-in-fn [:id :file_id] to-key 
                            [:create_ts :exec_ts] tc/to-sql-time)))

(defentity book
  (entity-fields :id :title :authors :language :edition :npages
                 :pubdate :publisher :isbn10 :isbn13
                 :tags :notes)
  (prepare (h/updates-in-fn [:id] to-key :npages to-int
                            [:pubdate] tc/to-sql-time)))

(defentity bookformat
  (entity-fields :id :book_id :format :notes)
  (prepare (h/updates-in-fn [:id :book_id] to-key)))

(defentity file
  (entity-fields :id :fullpath :filename :folder :filesize :ts :ts_cet
                 :md5 :directory_id :relfile_id 
                 :goal :importance :computer :srcbak)
  (prepare (h/updates-in-fn [:id :directory_id :relfile_id] to-key :filesize to-int
                            [:ts] tc/to-sql-time)))

(defentity relfile
  (entity-fields :id :bookformat_id :relpath :filename :relfolder :filesize :ts :ts_cet
                 :md5 :notes)
  (prepare (h/updates-in-fn [:id :bookformat_id] to-key :filesize to-int
                            [:ts] tc/to-sql-time)))





;; TODO alles hieronder een keertje weg.

;; TODO testen van wedstrijd-insert en -update. Vooral met prepare function.
;; TODO lijk zelfs een omvattende defentity te kunnen maken, waarbij je datatype kunt
;; opgeven, ook in Tcl zo gedaan. Dan hiermee een prepare functie aanmaken.
;; mss ook def's (deels) uit DB structuur te lezen (gebeurt nu ook al), maar has-one etc
;; niet 1-op-1 uit f.keys af te leiden.
(defentity wedstrijd
  (entity-fields :id :team :lokatie :datumtijd :scheids_nodig
                 :opmerkingen :naam :date_inserted :date_checked
                 :notes)
  (has-one scheids {:fk :wedstrijd})
  (prepare (h/updates-in-fn [:id :team] to-key :scheids_nodig to-int
                            [:datumtijd :date_inserted :date_checked] tc/to-sql-time))
  ;; TODO refs toevoegen: team, en kan_wedstrijd_fluiten
  )

(defentity team
  (entity-fields :id :naam :scheids_nodig :opmerkingen)
  (has-many kan_team_fluiten {:fk :team})
  (prepare (h/updates-in-fn :id to-key :scheids_nodig to-int)))

(defentity persoon
  (entity-fields :id :naam :email :telnrs :opmerkingen :afko)
  (has-many scheids {:fk :persoon})
  (has-many afwezig {:fk :persoon})
  (has-many kan_team_fluiten {:fk :persoon})
  (has-many costfactor {:fk :persoon})
  (has-many persoon_team {:fk :persoon})
  (prepare (h/updates-in-fn [:id] to-key)))

(defentity afwezig
  (entity-fields :id :eerstedag :laatstedag :opmerkingen)
  (belongs-to persoon {:fk :persoon})
  (prepare (h/updates-in-fn [:id :persoon] to-key
                          [:eerstedag :laatstedag] tc/to-sql-date)))

(defentity kan_team_fluiten
  (entity-fields :id :waarde :opmerkingen)
  (belongs-to persoon {:fk :persoon})
  (belongs-to team {:fk :team})
  (prepare (h/updates-in-fn [:id :persoon :team] to-key :waarde to-float)))

(defentity costfactor
  (entity-fields :id :speelt_zelfde_dag :factor :opmerkingen)
  (belongs-to persoon {:fk :persoon})
  (prepare (h/updates-in-fn [:id :persoon] to-key
                            :speelt_zelfde_dag to-int :factor to-float)))

(defentity scheids
  (entity-fields :id :speelt_zelfde_dag :status)
  (belongs-to wedstrijd {:fk :wedstrijd})
  (belongs-to persoon {:fk :persoon})
  (prepare (h/updates-in-fn [:id :persoon :wedstrijd] to-key
                            :speelt_zelfde_dag to-int )))

(defentity scheids_history
  (entity-fields :id :date_changed :opmerkingen :persoon_new)
  (belongs-to wedstrijd {:fk :wedstrijd})
  (belongs-to persoon {:fk :persoon_old})
  ;; two refs to the same object is problematic, so only one belongs-to persoon.
  (prepare (h/updates-in-fn [:id :persoon_new :persoon_old :wedstrijd] to-key
                            :date_changed tc/to-sql-time))) 

(defentity persoon_team
  (entity-fields :id :soort)
  (belongs-to persoon {:fk :persoon})
  (belongs-to team {:fk :team})
  (prepare (h/updates-in-fn [:id :persoon :team] to-key)))

