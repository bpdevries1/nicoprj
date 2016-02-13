(ns mediaweb.models.entities
  (:use korma.db korma.core)
  (:require [clojure.string :as string]
            [clj-time.core :as t]
            [clj-time.coerce :as tc]
            [clj-time.format :as tf]
            [libndv.core :as h]
            [libndv.coerce :refer [to-float to-int to-key]]))

(declare action)
(declare author)
(declare book)
(declare bookauthor)
(declare bookformat)
(declare directory)
(declare parent-directory)
(declare file)
(declare relfile)

;; TODO: naast prepare ook functies andere kant op: automatisch sql-date-time omzetten naar
;; clojure date-time. Maar dit lijkt niet echt nodig.
(defentity action
  (entity-fields :id :create_ts :exec_ts :exec_output :exec_stderr :exec_status
                 :action :fullpath_action :fullpath_other :notes)
  (belongs-to file {:fk :file_id})
  (prepare (h/updates-in-fn [:id :file_id] to-key 
                            [:create_ts :exec_ts] tc/to-sql-time)))

(defentity author
  (entity-fields :id :firstname :lastname :fullname :notes)
  (has-many bookauthor {:fk :author_id})
  (prepare (h/updates-in-fn [:id] to-key)))

(defentity book
  (entity-fields :id :title :authors :language :edition :npages
                 :pubdate :publisher :isbn10 :isbn13
                 :tags :notes)
  (has-many bookauthor {:fk :book_id})
  (has-many bookformat {:fk :book_id})
  (prepare (h/updates-in-fn [:id] to-key :npages to-int
                            [:pubdate] tc/to-sql-time)))

(defentity bookauthor
  (entity-fields :id :notes)
  (belongs-to book {:fk :book_id})
  (belongs-to author {:fk :author_id})
  (prepare (h/updates-in-fn [:id :book_id :author_id] to-key)))

(defentity bookformat
  (entity-fields :id :format :notes)
  (belongs-to book {:fk :book_id})
  (has-many relfile {:fk :bookformat_id})
  (prepare (h/updates-in-fn [:id :book_id] to-key)))

(defentity directory
  #_(alias :dir2) ;; dit werkt zo niet, waarsch met alias alleen (table def) bedoelt.
  (entity-fields :id :computer :parent_folder :fullpath :notes)
  ;; 2016-01-22 removed belongs-to directory, to avoid confusion with has-many.
  #_(belongs-to directory {:fk :parent_id})
  (has-many directory {:fk :parent_id})
  (has-many file {:fk :directory_id})
  (prepare (h/updates-in-fn [:id :parent_id] to-key)))

;; TODO: should be possible with alias or correct use of with to navigate to either parent or children.
;; could (def parent-directory directory) work?
#_(defentity parent-directory
  (table :directory)
  (entity-fields :id :computer :parent_folder :fullpath)
  (belongs-to parent-directory {:fk :parent_id})
  (has-many directory {:fk :parent_id})
  (has-many file {:fk :directory_id})
  (prepare (h/updates-in-fn [:id :parent_id] to-key)))

(defentity file
  (entity-fields :id :fullpath :filename :folder :filesize :ts :ts_cet
                 :md5 :goal :importance :computer :srcbak :notes)
  (has-many action {:fk :file_id})
  (belongs-to directory {:fk :directory_id})
  (belongs-to relfile {:fk :relfile_id})
  (prepare (h/updates-in-fn [:id :directory_id :relfile_id] to-key
                            :filesize to-int
                            :ts tc/to-sql-time)))

(defentity relfile
  (entity-fields :id :relpath :filename :relfolder :filesize :ts :ts_cet
                 :md5 :notes)
  (belongs-to bookformat {:fk :bookformat_id})
  (has-many file {:fk :relfile_id})
  (prepare (h/updates-in-fn [:id :bookformat_id] to-key :filesize to-int
                            [:ts] tc/to-sql-time)))

;; groups, tags and relations, not specific to one kind of object.
(declare itemgroupquery)
(declare member)

(defentity itemgroup
  (entity-fields :id :name :notes :tags)
  (has-many itemgroupquery {:fk :itemgroup_id})
  (has-many member {:fk :itemgroup_id}))

(defentity itemgroupquery
  (entity-fields :id :name :type :query :notes)
  (belongs-to itemgroup {:fk :itemgroup_id})
 )

(defentity member
  (entity-fields :id :type :item_table :item_id :title)
  (belongs-to itemgroup {:fk :itemgroup_id}))

(defentity relation
  (entity-fields :id :from_table :from_id :to_table :to_id :type))

(defentity tags
  (entity-fields :id :item_table :item_id :tags))

