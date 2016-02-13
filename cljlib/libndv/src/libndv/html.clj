(ns libndv.html
  (:require [clj-time.coerce :as tc]
            [clj-time.core :as t]
            [clj-time.format :as tf]
            [clojure.pprint :refer [pprint]]
            [clojure.set :as set]
            [clojure.set :refer [intersection]]
            [compojure.core :refer :all]
            [hiccup.form :refer [form-to text-field submit-button text-area
                                 drop-down hidden-field]]
            [hiccup.page :refer [html5 include-js include-css]]
            [potemkin.macros :as pm]
            [ring.util.response :as response]))

;; TODO clean up require list above. Refactor-tools?

(defn tr-tds
  "helpers for tables.
   each arg can either be a function (ifn?) to be applied to item,
   or a string etc to be directly appended."
  [item & args]
  (apply vector :tr
         (map
          (fn [el]
            (let [hiccup-el (cond
                              (fn? el) (el item)
                              (keyword? el) (el item)
                              true el)
                  input-type (:type (if (sequential? hiccup-el) (second hiccup-el)))]
              (if (= input-type "hidden")
                hiccup-el
                [:td hiccup-el ]))
            ) args)))

(defn object-href [obj id naam]
  [:a {:href (str "/" obj "/" id)} naam])

;; gensym usage in different scopes is a known problem.
;; potemkin.macros/unify-gemsyms provides a solution.
;; idee om meeste in een functie te doen, en macro als kleine wrapper, zie macro boek.
;; TODO - hier oplossen als part geen inhoud heeft, dan ook geen title/row in main table. -> voorlopig niet echt nodig.
(defmacro def-object-page
  "Create a function <fn-name> to view an object page.
  params in map:
  page-name     - String
  parts         - {:title String :part-fn (Fn [Object -> Html]}
  model-read-fn - (Fn [id -> Object])
  name-fn       - (Fn [Object -> String])
  debug         - boolean
  
  Defines       - (Fn [id -> Html])
  "
  [fn-name {:keys [base-page-fn page-name parts model-read-fn name-fn debug]}]
  (pm/unify-gensyms
   `(defn ~fn-name [id#]
      (let [obj## (~model-read-fn id#)
            page-title# (str (~name-fn obj##) " - " ~page-name)]
        (~base-page-fn
         page-title#
         [:h1 ~(if debug
                 `(str (~name-fn obj##) " [" (:id obj##) "]")
                 `(~name-fn obj##))]
         [:table.table
          [:tbody
           ~@(for [{:keys [title part-fn]} parts]
               ;; TODO hier dynamische if bij, die tr alleen aanmaakt als er data zit in resultaat
               ;; van de part-fn call.
               [:tr
                [:th.span1 title]
                [:td.span10 `(~part-fn obj##)]])]])))))

(defmacro def-page
  "Create a function <fn-name> to view a generic page with header and base-page.
  params in map:
  page-name     - String
  page-fn       - (Fn [Obj -> Html-Table])
  
  Defines       - (Fn [() -> Html])
  "
  [fn-name {:keys [base-page-fn page-name page-fn]}]
  (pm/unify-gensyms
   `(defn ~fn-name []
      (~base-page-fn ~page-name
                 [:div.row.admin-bar] 
                 [:h1 ~page-name]
                 (~page-fn nil)))))

(defmacro def-object-form
  "Create a function <fn-name> to show a form for (part of) and object.
  fn-name       - name of function to def
  obj-var       - name of var to use in other forms in this def.

  (unnamed) map with keys:
  actions       - :edit and/or :delete in a #{set}. Nil for just :edit
  obj-type      - [Req] type of object as a string, like 'team' or 'persoon'
  obj-part      - optional, string like 'algeemn'
  fields        - is a Seq of [Map or Form]
  submit-label  - label on submit button.

  field-as-map  - :label, :field, :format-fn, :attrs, :ftype
  field-as-form - eg (drop-down :persoon <list> <id>)

  Map:

  Form:
  (hickup) form in which obj-var can be used."
  [fn-name obj-var {:keys [actions obj-type obj-part fields submit-label]}]
  (pm/unify-gensyms
   (let [actions2 (or actions #{:edit})]
     `(defn ~fn-name [~obj-var]
        [:div
         (form-to
          [:post (str "/" ~(name obj-type) "/" (or (:id ~obj-var) "0")
                      ~(if obj-part (str  "/" (name obj-part))))]
          ;; 2 items per fields are needed, flattened, so for cannot be used? concat/for should work.
          ~@(mapcat 
             (fn [field-form]
               (list
                (if (map? field-form)
                  ;; use map-defnition of field, suitable for most standard fields.
                  (let [{:keys [label field ftype attrs format-fn]} field-form]
                    `(~(or ftype `text-field)
                      (merge {:type :text :placeholder ~label :title ~label} ~attrs)
                      ~(if (:readonly attrs) :_READONLY_ field)
                      (~(or format-fn `identity) (~field ~obj-var))))
                  ;; else: use customised form, like drop-down.
                  field-form)
                [:br])
               ) fields)
          ~(if (:edit actions2)
             `(submit-button {:class "btn btn-primary" :name :edit}
                             ~(or submit-label "Pas gegevens aan")))
          ~(if (:delete actions2)
             `(submit-button {:class "btn" :name :delete} "Delete")))
         ]))))

;; 9-12-2015 deze nu niet meer nodig, wel aardig als template als je van een functie/macro de
;; params wilt aanpassen.
#_(defmacro def-objects-form2
  "Define a function <fn-name> to view/edit a table of values
   main-obj-type - string (eg persoon)
   sub-bj-type - string (eg persoon-team)
   actions - either nil for all actions :add, :edit, :delete or a set of actions.

   Returns - (Fn [Obj -> Html-Table])
  "
  [fn-name obj-var sub-var {:keys [main-obj-type sub-obj-type model-read-fn actions columns] :as m}]
  `(defn ~fn-name [])
  (pprint
   `(def-objects-form
      ~fn-name ~obj-var ~sub-var
      ~(assoc m
              :columns
              (mapv #(hash-map
                      :width (first %)
                      :name (second %)
                      :form (nth % 2)) columns)))))

;; TODO best een grote macro, in stukken te verdelen? mss delen gelijk met form en table macro's?
;; mogelijk de letfn er tussenuit, als losse functie. Mss een defmacro-
;; maar eerst maar eens meer gebruiken, kijken of het nog anders moet.
;; TODO obj-types als :keyword meegeven? Lijkt conceptueel beter.
;; niet zozeer een class dat er ook methods aan hangen. Vgl ADT, abstract data type.
;; TODO: alleen een row-form maken als :edit aan staat.
;; TODO: nu let-form voor optional params, zou ook direct in fn-def moeten kunnen. Wel ergens voorbeelden gezien, Korma?
;; TODO: mogelijk kan main-key ook een set/seq zijn ipv 1 :keyword.
(defmacro def-objects-form
  "Define a function <fn-name> to view/edit a table of values
   main-type     - [Req] :keyword (eg :persoon)
   main-key      - [Opt] :keyword (eg :itemgroup_id). If not set, same as main-type.
   row-type      - [Req] :keyword (eg :persoon-team)
   model-read-fn - (Fn [id -> <List of object-maps>])
   actions       - either nil for all actions :add, :edit, :delete or a set of actions,
                   can also be :add-get
   columns       - List of column-map:
                   :width w :name n :form f :attrs attrs
                   f - either custom-form or Map :label :field :ftype :attrs :format-fn
                   attrs - for <td>, eg {:align :right}
   Returns       - (Fn [Obj -> Html-Table])
  "
  [fn-name main-var row-var {:keys [main-type main-key row-type
                                    model-read-fn actions columns] :as m}]
  (pm/unify-gensyms
   (let [actions2 (or actions #{:add :edit :delete})
         main-key2 (or main-key main-type)]
     `(defn ~fn-name [~main-var]
        (letfn [(row-form## [~row-var]
                  [:tr
                   (form-to
                    [:post (str "/" ~((fnil name "") row-type) "/" (or (:id ~row-var) 0))]
                    ~@(for [{:keys [attrs form]} columns]
                        [:td attrs (if (map? form)
                               ;; use map-defnition of field, suitable for most standard fields.
                               (let [{:keys [label field ftype attrs format-fn]} form]
                                 `(~(or ftype `text-field)
                                   (merge {:type :text :placeholder ~label} ~attrs)
                                   ~field
                                   (if ~row-var (~(or format-fn `identity) (~field ~row-var)))))
                               ;; else: use customised form, like drop-down.
                               form)])
                    (hidden-field ~main-key2 (:id ~main-var))
                    [:td
                     ~(if (:edit actions2)
                        `(if ~row-var
                           (submit-button {:class "btn btn-primary"} "Wijzig")))
                     ~(if (:add actions2)
                        `(if-not ~row-var
                           (submit-button {:class "btn btn-primary"} "Nieuw")))])
                   ;; here outside of the first update/new form.
                   ~(if (:delete actions2)
                      `(if ~row-var
                         [:td
                          (form-to
                           [:post (str "/" ~(name row-type) "/" (:id ~row-var) "/delete")]
                           (hidden-field ~main-key2 (:id ~main-var))
                           (submit-button {:class "btn btn-primary"} "Verwijder"))]))])]
          [:div
           ~(if (:add-get actions2)
              [:tr [:td
                    [:a {:href (str "/" (name row-type) "/0")} "Add new"]]])
           [:table.table
            [:thead
             [:tr
              ~@(for [{:keys [width name]} columns]
                  [:th {:width (str width "%")} name])
              ~(if-not (empty? (intersection #{:add :edit :delte} actions2))
                 [:th "Actie"])]]
            [:tbody
             (for [~row-var (~model-read-fn (:id ~main-var))]
               (row-form## ~row-var))
             ;; de if hier is toch nodig, anders velden getoond, maar geen button.
             ~(if (:add actions2) `(row-form## nil))]]])))))

;; TODO: wil optie om meervoud (bv itemgroupqueries) niet op nemen, als 'ie op nil staat. Maar
;; dan is name van de endpoint def ook nil. Code gaat waarsch nog wel wijzigen, ook met paginering, dus voorlopig Q&D oplossen door lege functie def in views.
;; TODO: in def-view-crud geef je namespace wel op als symbol, dus zonder quotes. Kan dus wel!
(defmacro def-with-default-routes
  "Define 4 default routes for an object, and also specific given routes.
   obj-type   - [String] singular of object type, eg 'file'
   obj-types  - [String] multiple of object type, eg 'files'
   view-ns    - [String] namespace of view functions, eg 'mediaweb.views.file'
   rest       - other route definitions.
  "
  [obj-type obj-types view-ns & rest]
  `(defn ~(symbol obj-types) [config#]
     (routes
      (GET ~(str "/" obj-types) []
           (~(symbol view-ns obj-types)))
      ;; ~'id used to explicity use 'id' as param name, not gensym one. Compojure needs this
      ;; to bind to :id.
      (GET ~(str "/" obj-type "/:id") [~'id]
           (~(symbol view-ns obj-type) ~'id))
      (POST ~(str "/" obj-type "/:id") [~'id & ~'params]
            (~(symbol view-ns (str obj-type "-update")) ~'id ~'params))
      (POST ~(str "/" obj-type "/:id/delete") [~'id & ~'params]
            (~(symbol view-ns (str obj-type "-delete")) ~'id ~'params))
      ~@rest)))

