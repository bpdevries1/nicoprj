# coding: utf8
# Model voor scheidsrechters
#########################################################################
## This scaffolding model makes your app work on Google App Engine too
#########################################################################

if request.env.web2py_runtime_gae:            # if running on Google App Engine
    db = DAL('gae')                           # connect to Google BigTable
    session.connect(request, response, db=db) # and store sessions and tickets there
    ### or use the following lines to store sessions in Memcache
    # from gluon.contrib.memdb import MEMDB
    # from google.appengine.api.memcache import Client
    # session.connect(request, response, db=MEMDB(Client())
else:                                         # else use a normal relational database
    # db = DAL("mysql://nico:pclip01;@localhost:3306/scheids")
    db = DAL("mysql://scheids:scheids@localhost:3306/scheids")
## if no need for session
# session.forget()

#########################################################################
## Here is sample code if you need for 
## - email capabilities
## - authentication (registration, login, logout, ... )
## - authorization (role based authorization)
## - services (xml, csv, json, xmlrpc, jsonrpc, amf, rss)
## - crud actions
## comment/uncomment as needed

from gluon.tools import *
auth=Auth(globals(),db)                      # authentication/authorization
auth.settings.hmac_key='fddbe104-a4bb-41f2-9870-8f18fb5bc1fa'
auth.define_tables()                         # creates all needed tables
crud=Crud(globals(),db)                      # for CRUD helpers using auth
service=Service(globals())                   # for json, xml, jsonrpc, xmlrpc, amfrpc

# 1-1-2011 NdV webgrid opgehaald van http://web2pyslices.com/main/slices/take_slice/39
webgrid = local_import('webgrid')

# crud.settings.auth=auth                      # enforces authorization on crud
# mail=Mail()                                  # mailer
# mail.settings.server='smtp.gmail.com:587'    # your SMTP server
# mail.settings.sender='you@gmail.com'         # your email
# mail.settings.login='username:password'      # your credentials or None
# auth.settings.mailer=mail                    # for user email verification
# auth.settings.registration_requires_verification = True
# auth.settings.registration_requires_approval = True
# auth.messages.verify_email = \
#  'Click on the link http://.../user/verify_email/%(key)s to verify your email'
## more options discussed in gluon/tools.py
#########################################################################

#########################################################################
## Define your tables below, for example
##
## >>> db.define_table('mytable',Field('myfield','string'))
##
## Fields can be 'string','text','password','integer','double','boolean'
##       'date','time','datetime','blob','upload', 'reference TABLENAME'
## There is an implicit 'id integer autoincrement' field
## Consult manual for more options, validators, etc.
##
## More API examples for controllers:
##
## >>> db.mytable.insert(myfield='value')
## >>> rows=db(db.mytable.myfield=='value').select(db.mytable.ALL)
## >>> for row in rows: print row.id, row.myfield
#########################################################################
import datetime; now = datetime.datetime.now()

db.define_table('team',
                Field('naam', length=10),
                Field('scheids_nodig', 'integer'),
                Field('opmerkingen', length=255),
                migrate=False)

db.define_table('persoon',
                Field('naam', length=255),
                Field('email', length=255),
                Field('telnrs', length=255),
                Field('speelt_in', db.team),
                Field('opmerkingen', length=255),
                Field('nevobocode', length=10),
                migrate=False)

db.define_table('persoon_team',
                Field('persoon', db.persoon),
                Field('team', db.team),
                Field('soort', length=40),
                migrate=False)

db.define_table('zeurfactor',
                Field('persoon', db.persoon),
                Field('speelt_zelfde_dag', 'integer'),
                Field('factor', 'double'),
                Field('opmerkingen', length=255),
                migrate=False)

# 1-1-2010 NdV datum vervangen door eerstedag en laatstedag, was in tcl scripts al langer zo. Ook 'nomigration' doen? 
db.define_table('afwezig', 
                Field('persoon', db.persoon),
                Field('eerstedag', 'date'),
                Field('laatstedag', 'date'),
                Field('opmerkingen', length=255),
                migrate=False)

# lokatie: alleen uit of thuis
# ook naam nodig, om naar te verwijzen
db.define_table('wedstrijd',
                Field('naam', length=255),
                Field('team', db.team),
                Field('lokatie', length=10),
                Field('datumtijd', 'datetime'),
                Field('scheids_nodig', 'integer'),
                Field('opmerkingen', length=255),
                Field('date_inserted', 'datetime', default=now),
                Field('date_checked', 'datetime', default=now),
                migrate=False)

db.define_table('scheids',
                Field('scheids', db.persoon),
                Field('wedstrijd', db.wedstrijd),
                Field('speelt_zelfde_dag', 'integer'),
                Field('opmerkingen', length=255),
                Field('date_inserted', 'datetime', default=now),
                Field('status', length=20),
                Field('waarde', 'double'),
                migrate=False)

db.define_table('kan_team_fluiten',
                Field('scheids', db.persoon),
                Field('team', db.team),
                Field('waarde', 'double', default=1.0),
                Field('opmerkingen', length=255),
                migrate=False)

db.define_table('kan_wedstrijd_fluiten',
                Field('scheids', db.persoon),
                Field('wedstrijd', db.wedstrijd),
                Field('waarde', 'double', default=1.0),
                Field('speelt_zelfde_dag', 'integer'),
                Field('opmerkingen', length=255),
                Field('date_inserted', 'datetime', default=now),
                migrate=False)

db.team.naam.requires = [IS_NOT_EMPTY(), IS_NOT_IN_DB(db, 'team.naam')]

db.persoon_team.persoon.requires = IS_IN_DB(db, 'persoon.id', 'persoon.naam')
db.persoon_team.team.requires = IS_IN_DB(db, 'team.id', 'team.naam')

# 30-12-2010 interface is stiekem toch veranderd.
# db.zeurfactor.persoon.requires = IS_IN_DB(db, 'persoon.id', 'persoon.naam')
db.zeurfactor.persoon.requires = IS_IN_DB(db, db.persoon.id, '%(naam)s')
db.zeurfactor.speelt_zelfde_dag.requires = IS_NOT_EMPTY()
db.zeurfactor.factor.requires = IS_NOT_EMPTY()

db.afwezig.persoon.requires = IS_IN_DB(db, 'persoon.id', 'persoon.naam')
db.afwezig.eerstedag.requires = [IS_NOT_EMPTY(), IS_DATE()]
db.afwezig.laatstedag.requires = [IS_NOT_EMPTY(), IS_DATE()]

db.persoon.naam.requires = [IS_NOT_EMPTY(), IS_NOT_IN_DB(db, 'persoon.naam')]

# 1-1-2011 speelt_in doet ook vaag, ook aanpassen, helpt alleen niet, nog steeds overal 'None'
# db.persoon.speelt_in.requires = IS_IN_DB(db, 'team.id', 'team.naam')
db.persoon.speelt_in.requires = IS_IN_DB(db, db.team.id, '%(naam)s')

# @todo andere dynamische identificatie van team bepalen, hoe dit moet.
db.wedstrijd.naam.requires = [IS_NOT_EMPTY(), IS_NOT_IN_DB(db, 'wedstrijd.naam')]
# db.wedstrijd.team.requires = [IS_NOT_EMPTY(), IS_IN_DB(db, 'team.id', 'team.naam')]
# @vaag: blijkbaar moeten f.keys alleen in een requires, met lijst en not-empty gaat het niet goed.
db.wedstrijd.team.requires = IS_IN_DB(db, 'team.id', 'team.naam')
db.wedstrijd.lokatie.requires = IS_NOT_EMPTY()
db.wedstrijd.datumtijd.requires = [IS_NOT_EMPTY(), IS_DATETIME()]

db.scheids.scheids.requires = IS_IN_DB(db, 'persoon.id', 'persoon.naam')
db.scheids.wedstrijd.requires = IS_IN_DB(db, 'wedstrijd.id', 'wedstrijd.naam')

db.kan_team_fluiten.scheids.requires = IS_IN_DB(db, 'persoon.id', 'persoon.naam')
db.kan_team_fluiten.team.requires = IS_IN_DB(db, 'team.id', 'team.naam')

db.kan_wedstrijd_fluiten.scheids.requires = IS_IN_DB(db, 'persoon.id', 'persoon.naam')
db.kan_wedstrijd_fluiten.wedstrijd.requires = IS_IN_DB(db, 'wedstrijd.id', 'wedstrijd.naam')

# 1-1-2010 NdV wat experimenten met represent, zou eigenlijk in controller/view moeten.
def speelt_in_rep(speelt_in):
  if speelt_in: 
    db.team[speelt_in].naam
  else:
    'Geen team'

db.persoon.speelt_in.represent = speelt_in_rep

# andere dingen met represent, dat altijd de links getoond worden.
# sommige schermen zijn er (nog) niet, dan ook nog even geen link.
db.persoon.id.represent = lambda val: A(T(str(val)), _href=URL('scheidsrechters', 'persoon','show', args=str(val)))
db.wedstrijd.id.represent = lambda val: A(T(str(val)), _href=URL('scheidsrechters', 'wedstrijd','show', args=str(val)))
# db.afwezig.id.represent = lambda val: A(T(str(val)), _href=URL('scheidsrechters', 'afwezig','show', args=str(val)))
# db.kan_team_fluiten.id.represent = lambda val: A(T(str(val)), _href=URL('scheidsrechters', 'kan_team_fluiten','show', args=str(val)))
# db.kan_wedstrijd_fluiten.id.represent = lambda val: A(T(str(val)), _href=URL('scheidsrechters', 'kan_wedstrijd_fluiten','show', args=str(val)))
db.persoon_team.id.represent = lambda val: A(T(str(val)), _href=URL('scheidsrechters', 'persoon_team','show', args=str(val)))
db.scheids.id.represent = lambda val: A(T(str(val)), _href=URL('scheidsrechters', 'scheids','show', args=str(val)))
db.team.id.represent = lambda val: A(T(str(val)), _href=URL('scheidsrechters', 'team','show', args=str(val)))
#db.zeurfactor.id.represent = lambda val: A(T(str(val)), _href=URL('scheidsrechters', 'zeurfactor','show', args=str(val)))


