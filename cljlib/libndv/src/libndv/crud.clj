(ns libndv.crud
  (:use korma.db korma.core)
  (:require
   [ring.util.response :as response]
   [potemkin.macros :as pm]
   [libndv.coerce :refer [to-key]]))

;; TODO model-ns(symbol seems to be missing a space, but leave it for now.
(defn model-fn
  [model-ns obj-type-name action]
  (ns-resolve model-ns(symbol (str obj-type-name "-" action))))

;; TODO vervang params2## door params##, werkt het dan nog steeds, of dan clash met params## van
;; aanroepende functie? => lijkt goed, wordt toch wat onduidelijk, dus maar even op 2 laten staan.
(defn redir-url-fn
  "Return function to determine redirect url based on obj-type, redir-type, obj-id (possibly new) and params.
  if redir-type is nil, return a dummy function, which should not be used.
  Alternative is generate an error, but sometimes not all 3 functions (insert/update/delete) are needed/wanted."
  [obj-type redir-type]
  `(fn [obj-id2## params2##]
     (str "/" ~(name (or redir-type :none))
          ~(if (= obj-type redir-type)
             `(str "/" obj-id2##)
             ;; if redir-id not found in params, just redirect to the type, eg /personen.
             `(if-let [redir-id## (~(or redir-type :none) params2##)]
                (str "/" redir-id##))))))

(defn remove-readonly
  "Remove :_READONLY_ keys from m"
  [m]
  (select-keys m (remove #{:_READONLY_} (keys m))))

(defn get-action
  "Determine action (edit/delete) from runtime form parameters,
   given with :name :edit or :name :delete.
   Return vector with 2 items:
   - :edit or :delete
   - the map m without :edit and :delete keys."
  [m]
  [(first (filter #{:edit :delete} (keys m)))
   (select-keys m (remove #{:edit :delete} (keys m)))])

(defn def-view-crud-update
  "Define view function for updating (including new) objects. If delete button is pressed,
   redirect to delete view function.
   Map with named parameters:
   obj-type     - :keyword : required, object type
   redir-type   - :keyword : redirect to this object-type after action
   pre-fn       - (Fn [ParamsMap -> ParamsMap]) : optional, to preprocess the given params map. Not implemented yet!
   model-ns     - namespace with model functions (<object>-insert|update|delete)
  "
  [{:keys [obj-type redir-type pre-fn model-ns] :as m}]
  (pm/unify-gensyms
   (let [obj-type-name ((fnil name "<empty :obj-type") obj-type)
         redir-type-name ((fnil name "<empty :redir-type") redir-type)]
     `(defn ~(symbol (str obj-type-name "-update")) [id## params##]
        (println (str "dvcu: " params##))
        (let [params2## (remove-readonly params##)
              [action## params3##] (get-action params2##)]
          (if (= action## :delete)
            (~(symbol (str obj-type-name "-delete")) id## params3##)
            (let [obj-id## (if (nil? (to-key id##))
                             (~(model-fn model-ns obj-type-name "insert") params3##)
                             (~(model-fn model-ns obj-type-name "update") id## params3##))]
              (response/redirect-after-post
               (~(redir-url-fn obj-type redir-type) obj-id## params3##)))))))))

;; delete functie ook met params, voor evt redirect in de params.
(defn def-view-crud-delete
  "Define view function for updating (including new) objects.
   Map with named parameters:
   obj-type  - :keyword : required, object type
   redir-type - :keyword : redirect to this after deleting an object.
   pre-fn - (Fn [ParamsMap -> ParamsMap]) : optional, to preprocess the given params map. Not implemented yet!
   model-ns   - "
  [{:keys [obj-type redir-type pre-fn model-ns] :as m}]
  (let [obj-type-name ((fnil name "<empty :obj-type") obj-type)]
    `(defn ~(symbol (str obj-type-name "-delete")) [id## params##]
       (~(model-fn model-ns obj-type-name "delete") id##)
       (response/redirect-after-post
        (~(redir-url-fn obj-type redir-type) id## params##)))))

(defmacro def-view-crud
  "Define view function for updating (including new) and deleting objects.
   Named parameters:
   obj-type  - :keyword : required, object type
   redir-update-type - :keyword : redirect to this after updating/inserting an object.
   redir-delete-type - :keyword : redirect to this after deleting an object.
   pre-fn - (Fn [ParamsMap -> ParamsMap]) : optional, to preprocess the given params map. Not implemented yet!
   model-ns   - "
  [& {:keys [obj-type redir-update-type redir-delete-type pre-fn model-ns] :as m}]
  (pm/unify-gensyms
   `(do
      ;; delete is called from update, so define first.
      ~(def-view-crud-delete (assoc m :redir-type redir-delete-type))
      ~(def-view-crud-update (assoc m :redir-type redir-update-type)))))

;; model functions
;; TODO replace if-not nil? insert-post-fn with if insert-post-fn, then test with new person and costfactors.
(defn def-model-crud-insert
  "Define model function for inserting objects.
   Returns id of inserted object.
   Map with named parameters:
   obj-type        - :keyword : required, object type
    pre-fn         - (Fn [paramsMap -> paramsMap]) optional, to call before insert/update (delete does not have params)
   insert-post-fn  - (Fn [id -> void]) optional, function to call with id after the main insert."
  [{:keys [obj-type pre-fn insert-post-fn] :as m}]
  (let [obj-type-name ((fnil name "<empty :obj-type") obj-type)]
    `(defn ~(symbol (str obj-type-name "-insert")) [params##]
       (let [params2## ~(if pre-fn `(~pre-fn params##) `params##)
             id## (:id (insert ~(symbol obj-type-name)
                               (values params2##)))]
         ~(if-not (nil? insert-post-fn)
            `(~insert-post-fn id##))
         id##))))

(defn def-model-crud-update
  "Define model function for updating objects.
   Map with named parameters:
   obj-type       - :keyword : required, object type
   pre-fn         - (Fn [params -> params]) optional, to call before insert/update (delete does not have params)
   update-post-fn - (Fn [id -> void]) optional, function to call with id after the main update.
                  not implemented yet, not needed yet."
  [{:keys [obj-type pre-fn update-post-fn] :as m}]
  (let [obj-type-name ((fnil name "<empty :obj-type") obj-type)]
    `(defn ~(symbol (str obj-type-name "-update")) [id## params##]
       (let [params2## ~(if pre-fn `(~pre-fn params##) `params##)]
         (println (str params##))
         (update ~(symbol obj-type-name)
                 (set-fields params2##)
                 (where {:id (to-key id##)})))
       id##)))

(defn def-model-crud-delete
  "Define model function for deleting objects.
   Map with named parameters:
   obj-type  - :keyword : required, object type
   delete-post-fn - (Fn [id -> void]) optional, function to call with id after the main delete.
                  not implemented yet, not needed yet."
  [{:keys [obj-type delete-post-fn] :as m}]
  (let [obj-type-name ((fnil name "<empty :obj-type") obj-type)]
    `(defn ~(symbol (str obj-type-name "-delete")) [id##]
       (delete ~(symbol obj-type-name)
               (where {:id (to-key id##)}))
       id##)))

(defmacro def-model-crud
  "Define model functions for inserting, updating and deleting objects.
  Named parameters:
  obj-type       - :keyword : required, main object type
  insert-post-fn - (Fn [id -> void]) optional, function to call with id after the main insert.
  pre-fn         - (Fn [params -> params]) optional, to call before insert/update (delete does not have params)"
  [& {:as m}]
  (pm/unify-gensyms
   `(do
      ~(def-model-crud-insert m)
      ~(def-model-crud-update m)
      ~(def-model-crud-delete m))))
