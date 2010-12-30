# coding: utf8
# try something like
def index(): 
    # return dict(message="hello from persoon.py")
    # return personen()
    redirect(URL('personen'))

def personen():
    personen = db().select(db.persoon.ALL, orderby=db.persoon.naam)
    return dict(personen=personen)

@auth.requires_login()
def create():
    "creates a new persoon"
    form = crud.create(db.persoon, next=URL('index'))
    return dict(form=form)
  
@auth.requires_login()
def show():
    "shows a persoon"
    this_persoon = db.persoon(request.args(0)) or redirect(URL('personen'))
    return dict(persoon=this_persoon)

@auth.requires_login()
def edit():
    # persoon = db(db.persoon.id==request.args(0)).select().first()
    this_persoon = db.persoon(request.args(0)) or redirect(URL('personen'))
    # form = SQLFORM(db.persoon)
    # form = crud.update(db.persoon, this_persoon, message='Your change is handled')
    form = crud.update(db.persoon, this_persoon, 
      next=URL('show',args=request.args))
    # form.vars.id = persoon.id
    # form.vars = persoon
    #if form.accepts(request.vars, session):
    #    response.flash = 'Your change is handled'
    # return dict(persoon=persoon, form=form)
    return dict(form=form)

def search():
    "an ajax persoon search page"
    return dict(form=FORM(INPUT(_id='keyword', _name='keyword', 
      _onkeyup="ajax('bg_find', ['keyword'], 'target');")),
      target_div=DIV(_id='target'))
    
def bg_find():
    "an ajax callback that returns a <ul> of links to personen"
    pattern = '%' + request.vars.keyword.lower() + '%'
    personen = db(db.persoon.naam.lower().like(pattern)).select(orderby=db.persoon.naam)
    items = [A(row.naam, _href=URL('show',args=row.id)) for row in personen]
    return UL(*items).xml()

# 30-12-2010 NdV even onduidelijk of deze hier ook moet, in elke controller. Ik hoop het niet.
def user():
    """
    exposes:
    http://..../[app]/default/user/login 
    http://..../[app]/default/user/logout
    http://..../[app]/default/user/register
    http://..../[app]/default/user/profile
    http://..../[app]/default/user/retrieve_password
    http://..../[app]/default/user/change_password
    use @auth.requires_login()
        @auth.requires_membership('group name')
        @auth.requires_permission('read','table name',record_id)
    to decorate functions that need access control
    """
    return dict(form=auth())
      
