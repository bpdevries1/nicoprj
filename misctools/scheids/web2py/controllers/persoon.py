# coding: utf8
# try something like
def index(): 
    # return dict(message="hello from persoon.py")
    # return personen()
    redirect(URL('personen'))

def personen_old():
    personen = db().select(db.persoon.ALL, orderby=db.persoon.naam)
    select = crud.select(db.persoon)
    return dict(personen=personen, select_personen=select)

def links_right(tablerow,rowtype,rowdata):
    if rowtype != 'pager':
        links = tablerow.components[:2]
        del tablerow.components[:2]
        tablerow.components.extend(links)

# met nieuwe module
def personen():
    grid = webgrid.WebGrid(crud)
    # grid.datasource = db(db.persoon.id>0)
    # grid.datasource = db.persoon
    # bij left-clause is volgorde voor en achter de == belangrijk? => nee, gaat sowieso wel fout.
    query = (db.persoon.id > 0)
    # 1-1-2011 NdV Raar, onderstaande doet het niet, team niet gevonden. Meer ingewikkelde daaronder met koppeltabel doet het wel.
    # lijkt dus iets met waar de f.key in staat; bij foute staat deze in de bron-tabel, bij de goede in de koppel-tabel.
#    grid.datasource = db(query).select(db.persoon.id, db.persoon.naam, \
#      db.persoon.telnrs, db.persoon.email, db.persoon.opmerkingen, db.team.naam, \
#      left = db.team.on(db.persoon.team == db.team.id), \
#      orderby = db.persoon.naam)
    grid.datasource = db(query).select(db.persoon.id, db.persoon.naam,
      db.persoon_team.soort, db.team.naam,
      db.persoon.telnrs, db.persoon.email,
      db.persoon.nevobocode,
      left = ((db.persoon_team.on(db.persoon_team.persoon == db.persoon.id), (db.team.on(db.persoon_team.team == db.team.id)))),
      orderby = db.persoon.naam)
    
    grid.crud_function = 'data'
    grid.pagesize = 20
    
    grid.action_links = ['view', 'edit']
    grid.action_headers = ['view', 'edit']
    
    # 1-1-2011 NdV row is dus een geneste 'hashmap', dus dubbele ref.
    grid.view_link = lambda row: A(T("view"), _href=URL('scheidsrechters','persoon','show', args=row['persoon']['id']))
    grid.edit_link = lambda row: A(T("edit"), _href=URL('scheidsrechters','persoon','edit', args=row['persoon']['id']))
    grid.row_created = links_right
    
    return dict(grid=grid()) #notice the ()

# ook hier erbij, voor webgrid?
def data():
    return dict(form=crud())

# The WebGrid will use a field's represent function if present when rendering the cell. If you need more control, you can completely override the way a row is rendered.
# The functions that render each row can be replaced with your own lambda or function:

# 6-3-2011 wil vooralsnog geen login.
# @auth.requires_login()
def create():
    "creates a new persoon"
    form = crud.create(db.persoon, next=URL('index'))
    return dict(form=form)
  
  
def links_right(tablerow,rowtype,rowdata):
    if rowtype != 'pager':
        links = tablerow.components[:2]
        del tablerow.components[:2]
        tablerow.components.extend(links)

def make_grid(field):
    grid = webgrid.WebGrid(crud)
    grid.datasource = db(field == request.args(0)).select()
    grid.enabled_rows = ['header', 'add_links']
    grid.action_links = ['view', 'edit']
    grid.action_headers = ['view', 'edit']
    grid.row_created = links_right
    return grid

def make_grid_wedstrijden():
    grid = webgrid.WebGrid(crud)
    query = (db.scheids.scheids == request.args(0)) & (db.scheids.wedstrijd == db.wedstrijd.id)
    grid.datasource = db(query).select(db.wedstrijd.id, db.wedstrijd.datumtijd, db.wedstrijd.opmerkingen, db.scheids.status, db.scheids.speelt_zelfde_dag)
    grid.enabled_rows = ['header']
    grid.action_links = ['view', 'edit']
    grid.action_headers = ['view', 'edit']
    grid.view_link = lambda row: A(T("view"), _href=URL('scheidsrechters','wedstrijd','show', args=row['wedstrijd']['id']))
    grid.edit_link = lambda row: A(T("edit"), _href=URL('scheidsrechters','wedstrijd','edit', args=row['wedstrijd']['id']))
    
    grid.row_created = links_right
    return grid

# ktf: kan_team_fluiten
def make_grid_ktf():
    grid = webgrid.WebGrid(crud)
    query = (db.kan_team_fluiten.scheids == request.args(0)) & (db.kan_team_fluiten.team == db.team.id)
    grid.datasource = db(query).select(db.kan_team_fluiten.id, db.team.naam, db.kan_team_fluiten.waarde, db.kan_team_fluiten.opmerkingen)
    grid.enabled_rows = ['header', 'add_links']
    grid.action_links = ['view', 'edit']
    grid.action_headers = ['view', 'edit']
    grid.view_link = lambda row: A(T("view"), _href=URL('scheidsrechters','default','data/read/kan_team_fluiten', args=row['kan_team_fluiten']['id']))
    grid.edit_link = lambda row: A(T("edit"), _href=URL('scheidsrechters','default','data/update/kan_team_fluiten', args=row['kan_team_fluiten']['id']))
    
    grid.row_created = links_right
    return grid

# @todo van webgrid
# kan er misschien zelf inbouwen, evt alleen als optie:
# elk veld weergeven als link, ga naar view of edit page van dit object/record
# met de hele row en datarow info moet dit lukken. Dan ook koppelen aan crud object of iets wat kwaakt als een crud object (eigen links).
# hieronder de orig def van view_link.
#            self.view_link = lambda row: A(self.messages.view_link, _href=self.crud.url(f=self.crud_function, 
#                                                       args=['read', self.tablenames[0], 
#                                                             row[self.tablenames[0]]['id'] \
#                                                              if self.joined else row['id']]))          
#

# @auth.requires_login()
def show():
    "shows a persoon"
    form = crud.read(db.persoon, request.args(0)) or redirect(URL('personen'))

    # testje met represent
    # db.zeurfactor.speelt_zelfde_dag.represent = lambda val: 2 * val
    # db.zeurfactor.id.represent = lambda val: A(T(str(val)), _href=URL('scheidsrechters', 'zeurfactor','show', args=str(val)))
    
    zeur_factor_grid = make_grid(db.zeurfactor.persoon)
    zeur_factor_grid.fields = ['zeurfactor.id', 'zeurfactor.speelt_zelfde_dag', 'zeurfactor.factor', 'zeurfactor.opmerkingen']
    # zeur_factor_grid.fields = ['zeurfactor.speelt_zelfde_dag', 'zeurfactor.factor']
    zeur_factor_grid.field_headers = ['id', 'zelfde dag', 'factor', 'opmerkingen']
    zeur_factor_grid.view_link = lambda row: A(T("View"), _href=URL('scheidsrechters','zeurfactor','show', args=row['id']))
    # zeur_factor_grid.datarow = 'abc'
    # zeur_factor_grid.datarow = lambda row: row
    afwezig_grid = make_grid(db.afwezig.persoon)
    wedstrijden_grid = make_grid_wedstrijden()
    ktf_grid = make_grid_ktf()
    return dict(form=form, zeur_factor_grid=zeur_factor_grid(), afwezig_grid=afwezig_grid(), wedstrijden_grid=wedstrijden_grid(), ktf_grid=ktf_grid())
    # return dict(form=form)

# @auth.requires_login()
def show_orig():
    "shows a persoon"
    form = crud.read(db.persoon, request.args(0)) or redirect(URL('personen'))

    zeur_factor_grid = make_grid(db.zeurfactor.persoon)
    zeur_factor_grid.fields = ['zeurfactor.speelt_zelfde_dag', 'zeurfactor.factor', 'zeurfactor.opmerkingen']
    zeur_factor_grid.field_headers = ['zelfde dag', 'factor', 'opmerkingen']
    zeur_factor_grid.view_link = lambda row: A(T("View"), _href=URL('scheidsrechters','zeurfactor','show', args=row['id']))
    afwezig_grid = make_grid(db.afwezig.persoon)
    wedstrijden_grid = make_grid_wedstrijden()
    ktf_grid = make_grid_ktf()
    return dict(form=form, zeur_factor_grid=zeur_factor_grid(), afwezig_grid=afwezig_grid(), wedstrijden_grid=wedstrijden_grid(), ktf_grid=ktf_grid())
    # return dict(form=form)

# @auth.requires_login()
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
      
