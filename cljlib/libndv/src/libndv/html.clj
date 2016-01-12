(ns libndv.html
  (:require [clj-time.core :as t]
            [clj-time.coerce :as tc]
            [clj-time.format :as tf]
            [potemkin.macros :as pm]
            [hiccup.page :refer [html5 include-js include-css]]
            [hiccup.form :refer [form-to text-field submit-button text-area
                                 drop-down hidden-field]]
            [ring.util.response :as response]
            [clojure.set :refer [intersection]]
            [clojure.pprint :refer [pprint]]))

;; TODO clean up require list above.

;;; helpers for tables
;; each arg can either be a function (ifn?) to be applied to item,
;; or a string etc to be directly appended.
(defn tr-tds [item & args]
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
  fn-name -
  obj-var -

  (unnamed) map with keys:
  obj-type      - [Req] type of object as a string, like 'team' or 'persoon'
  obj-part      - optional, string like 'algeemn'
  fields        - is a Seq of [Map or Form]
  submit-label  - label on submit button.

  field-as-map  - :label, :field, :format-fn, :attrs, :ftype
  field-as-form - eg (drop-down :persoon <list> <id>)

  Map:

  Form:
  (hickup) form in which obj-var can be used."
  [fn-name obj-var {:keys [obj-type obj-part fields submit-label]}]
  (pm/unify-gensyms
   `(defn ~fn-name [~obj-var]
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
                   (merge {:type :text :placeholder ~label} ~attrs)
                   ~field
                   (~(or format-fn `identity) (~field ~obj-var))))
               ;; else: use customised form, like drop-down.
               field-form)
             [:br])
            ) fields)
       (submit-button {:class "btn btn-primary"}
                      ~(or submit-label "Pas gegevens aan"))))))

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
;; TODO alleen een row-form maken als :edit aan staat.
(defmacro def-objects-form
  "Define a function <fn-name> to view/edit a table of values
   main-type     - [Req] :keyword (eg :persoon)
   row-type      - [Req] :keyword (eg :persoon-team)
   model-read-fn - 
   actions       - either nil for all actions :add, :edit, :delete or a set of actions,
                   can also be :add-get
   columns       - 
   Returns       - (Fn [Obj -> Html-Table])
  "
  [fn-name main-var row-var {:keys [main-type row-type model-read-fn actions columns] :as m}]
  (pm/unify-gensyms
   (let [actions2 (or actions #{:add :edit :delete})]
     `(defn ~fn-name [~main-var]
        (letfn [(row-form## [~row-var]
                  [:tr
                   (form-to
                    [:post (str "/" ~((fnil name "") row-type) "/" (or (:id ~row-var) 0))]
                    ~@(for [{:keys [form]} columns]
                        [:td (if (map? form)
                               ;; use map-defnition of field, suitable for most standard fields.
                               (let [{:keys [label field ftype attrs format-fn]} form]
                                 `(~(or ftype `text-field)
                                   (merge {:type :text :placeholder ~label} ~attrs)
                                   ~field
                                   (if ~row-var (~(or format-fn `identity) (~field ~row-var)))))
                               ;; else: use customised form, like drop-down.
                               form)])
                    (hidden-field ~main-type (:id ~main-var))
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
                           (hidden-field ~main-type (:id ~main-var))
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


