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
    db = DAL("mysql://nico:pclip01;@localhost:3306/scheids")
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
                Field('opmerkingen', length=255))

db.define_table('persoon',
                Field('naam', length=255),
                Field('email', length=255),
                Field('telnrs', length=255),
                Field('speelt_in', db.team),
                Field('opmerkingen', length=255))

db.define_table('persoon_team',
                Field('persoon', db.persoon),
                Field('team', db.team),
                Field('soort', length=40))

db.define_table('zeurfactor',
                Field('persoon', db.persoon),
                Field('speelt_zelfde_dag', 'integer'),
                Field('factor', 'double'),
                Field('opmerkingen', length=255))

db.define_table('afwezig',
                Field('persoon', db.persoon),
                Field('datum', 'date'),
                Field('opmerkingen', length=255))

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
                Field('date_checked', 'datetime', default=now))

db.define_table('scheids',
                Field('scheids', db.persoon),
                Field('wedstrijd', db.wedstrijd),
                Field('speelt_zelfde_dag', 'integer'),
                Field('opmerkingen', length=255),
                Field('date_inserted', 'datetime', default=now),
                Field('status', length=20),
                Field('waarde', 'double'))

db.define_table('kan_team_fluiten',
                Field('scheids', db.persoon),
                Field('team', db.team),
                Field('waarde', 'double', default=1.0),
                Field('opmerkingen', length=255))

db.define_table('kan_wedstrijd_fluiten',
                Field('scheids', db.persoon),
                Field('wedstrijd', db.wedstrijd),
                Field('waarde', 'double', default=1.0),
                Field('speelt_zelfde_dag', 'integer'),
                Field('opmerkingen', length=255),
                Field('date_inserted', 'datetime', default=now))

db.team.naam.requires = [IS_NOT_EMPTY(), IS_NOT_IN_DB(db, 'team.naam')]

db.persoon_team.persoon.requires = IS_IN_DB(db, 'persoon.id', 'persoon.naam')
db.persoon_team.team.requires = IS_IN_DB(db, 'team.id', 'team.naam')

# 30-12-2010 interface is stiekem toch veranderd.
# db.zeurfactor.persoon.requires = IS_IN_DB(db, 'persoon.id', 'persoon.naam')
db.zeurfactor.persoon.requires = IS_IN_DB(db, db.persoon.id, '%(naam)s')
db.zeurfactor.speelt_zelfde_dag.requires = IS_NOT_EMPTY()
db.zeurfactor.factor.requires = IS_NOT_EMPTY()

db.afwezig.persoon.requires = IS_IN_DB(db, 'persoon.id', 'persoon.naam')
db.afwezig.datum.requires = [IS_NOT_EMPTY(), IS_DATE()]

db.persoon.naam.requires = [IS_NOT_EMPTY(), IS_NOT_IN_DB(db, 'persoon.naam')]
db.persoon.speelt_in.requires = IS_IN_DB(db, 'team.id', 'team.naam')

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
