# coding: utf8
def index():
    return dict(text="empty")

@auth.requires_login()
def create():
    "creates a new scheids"
    form = crud.create(db.scheids, next=URL('index'))
    return dict(form=form)

@auth.requires_login()
def show():
    "shows a scheids"
    form = crud.read(db.scheids, request.args(0)) or redirect(URL('index'))
    return dict(form=form)

@auth.requires_login()
def edit():
    this_scheids = db.scheids(request.args(0)) or redirect(URL('index'))
    form = crud.update(db.scheids, this_scheids, 
      next=URL('show',args=request.args))
    return dict(form=form)


