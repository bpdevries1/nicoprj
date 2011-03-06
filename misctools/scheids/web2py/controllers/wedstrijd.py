# coding: utf8
# try something like
def index(): 
    # return dict(message="hello from wedstrijd.py")
    # return wedstrijden()
    redirect(URL('wedstrijden'))

def wedstrijden_old():
    wedstrijden = db().select(db.wedstrijd.ALL, orderby=db.wedstrijd.datumtijd)
    select = crud.select(db.wedstrijd)
    return dict(wedstrijden=wedstrijden, select_wedstrijden=select)

def links_right(tablerow,rowtype,rowdata):
    if rowtype != 'pager':
        links = tablerow.components[:2]
        del tablerow.components[:2]
        tablerow.components.extend(links)

def wedstrijden():
    grid = webgrid.WebGrid(crud)
    # grid.datasource = db(db.wedstrijd.id>0)
    # grid.datasource = db.wedstrijd
    query = (db.wedstrijd.team == db.team.id) 
    grid.datasource = db(query).select(db.wedstrijd.id, db.wedstrijd.datumtijd, db.wedstrijd.lokatie, 
      db.team.naam, db.wedstrijd.opmerkingen, db.persoon.naam, db.scheids.status, 
      left = ((db.scheids.on(db.scheids.wedstrijd == db.wedstrijd.id), (db.persoon.on(db.scheids.scheids == db.persoon.id)))),
      orderby = db.wedstrijd.datumtijd)
    
    # Voorbeeld van: http://groups.google.com/group/web2py/browse_thread/thread/23ec20eab988df52
    # db((db.companyperson.person_id==db.person.id)&(db.companyperson.bedrijf_id==2))
    # \ ._select(db.person.first_name,db.person.last_name,db.profiletext.text,db.avatar.link,
    # \
    # left=((db.avatar.on(db.companyperson.person_id==db.avatar.person_id),\
    # (db.profiletext.on(db.companyperson.person_id==db.profiletext.person_id))))
    # \
    # ,orderby=db.profiletext.order) 

    # @todo iets met filter, eerst alleen thuis wedstrijden.
    grid.crud_function = 'data'
    grid.pagesize = 20
    # grid.enabled_rows = ['header']
    grid.action_links = ['view', 'edit']
    grid.action_headers = ['view', 'edit']
    grid.view_link = lambda row: A(T("view"), _href=URL('scheidsrechters','wedstrijd','show', args=row['wedstrijd']['id']))
    grid.edit_link = lambda row: A(T("edit"), _href=URL('scheidsrechters','wedstrijd','edit', args=row['wedstrijd']['id']))
    
    grid.row_created = links_right
    return dict(grid=grid()) #notice the ()

# ook hier erbij, voor webgrid?
def data():
    return dict(form=crud())

# The WebGrid will use a field's represent function if present when rendering the cell. If you need more control, you can completely override the way a row is rendered.
# The functions that render each row can be replaced with your own lambda or function:

# @auth.requires_login()
def create():
    "creates a new wedstrijd"
    form = crud.create(db.wedstrijd, next=URL('index'))
    return dict(form=form)
  
# @auth.requires_login()
def show():
    "shows a wedstrijd"
    form = crud.read(db.wedstrijd, request.args(0)) or redirect(URL('wedstrijden'))
    scheids_grid = webgrid.WebGrid(crud)
    query = (db.scheids.wedstrijd == request.args(0)) & (db.scheids.scheids == db.persoon.id)
    scheids_grid.datasource = db(query).select(db.scheids.id, db.persoon.naam, db.scheids.speelt_zelfde_dag, db.scheids.status)
    scheids_grid.enabled_rows = ['header']
    scheids_grid.action_links = ['view', 'edit']
    scheids_grid.action_headers = ['view', 'edit']

    scheids_grid.view_link = lambda row: A(T("view"), _href=URL('scheidsrechters','scheids','show', args=row['scheids']['id']))
    scheids_grid.edit_link = lambda row: A(T("edit"), _href=URL('scheidsrechters','scheids','edit', args=row['scheids']['id']))

    scheids_grid.row_created = links_right
    
    alt_grid = webgrid.WebGrid(crud)
    query = (db.kan_wedstrijd_fluiten.wedstrijd == request.args(0)) & (db.kan_wedstrijd_fluiten.scheids == db.persoon.id)
    alt_grid.datasource = db(query).select(db.kan_wedstrijd_fluiten.id, db.persoon.naam, 
      db.kan_wedstrijd_fluiten.speelt_zelfde_dag, db.kan_wedstrijd_fluiten.waarde, db.kan_wedstrijd_fluiten.opmerkingen)
    alt_grid.enabled_rows = ['header']
    # Hoef deze eigenlijk niet aan te kunnen passen.
    alt_grid.action_links = []
    alt_grid.action_headers = []

    alt_grid.view_link = lambda row: A(T("view"), _href=URL('scheidsrechters','kan_wedstrijd_fluiten','show', args=row['kan_wedstrijd_fluiten']['id']))
    alt_grid.edit_link = lambda row: A(T("edit"), _href=URL('scheidsrechters','kan_wedstrijd_fluiten','edit', args=row['kan_wedstrijd_fluiten']['id']))

    # alt_grid.row_created = links_right
    
    return dict(form=form, scheids_grid=scheids_grid(), alt_grid=alt_grid())

# @auth.requires_login()
def edit():
    this_wedstrijd = db.wedstrijd(request.args(0)) or redirect(URL('wedstrijden'))
    form = crud.update(db.wedstrijd, this_wedstrijd, 
      next=URL('show',args=request.args))
    return dict(form=form)

def search():
    "an ajax wedstrijd search page"
    return dict(form=FORM(INPUT(_id='keyword', _name='keyword', 
      _onkeyup="ajax('bg_find', ['keyword'], 'target');")),
      target_div=DIV(_id='target'))
    
def bg_find():
    "an ajax callback that returns a <ul> of links to wedstrijden"
    pattern = '%' + request.vars.keyword.lower() + '%'
    wedstrijden = db(db.wedstrijd.naam.lower().like(pattern)).select(orderby=db.wedstrijd.datumtijd)
    items = [A(row.naam, _href=URL('show',args=row.id)) for row in wedstrijden]
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
      
