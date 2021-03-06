# coding: utf8
# Model voor music
#
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
    # db = DAL('sqlite://storage.sqlite')       # if not, use SQLite or other DB
    db = DAL("mysql://qqq:qqq@localhost:3306/music")    
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
auth.settings.hmac_key='4fc4c4af-0d6d-4b1f-93e2-7519a10de447'
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

# gentype: musicfile, album, artist, ...
# @todo: add artist f.key i.s.o. artist name.
db.define_table('generic',
                Field('gentype', length=20),
                Field('freq', 'double', default=1.0),
                Field('freq_history', 'double', default=1.0),
                Field('play_count', 'integer', default=0))

db.define_table('artist', 
                Field('generic', db.generic),
                Field('path', length=255),
                Field('name', length=255),
                Field('notes', 'text'))

db.define_table('album', 
                Field('generic', db.generic),
                Field('path', length=255),
                Field('artist', db.artist),
                Field('name', length=255),
                Field('notes', 'text'))

db.define_table('musicfile', 
                Field('path', length=255),
                Field('file_exists', 'integer', default=1),
                Field('artistname', length=255),
                Field('trackname', length=255),
                Field('filesize', 'integer'),
                Field('seconds', 'integer'),
                Field('bitrate', 'integer'),
                Field('vbr', 'integer'),
                Field('notes', 'text'),
                Field('generic', db.generic),
                Field('album', db.album),
                Field('artist', db.artist))

db.define_table('played',
                Field('kind', length=10),
                Field('datetime', 'datetime', default=now),
                Field('generic', db.generic))

db.define_table('property',
                Field('name', length=50),
                Field('value', length=255),
                Field('generic', db.generic))

db.define_table('mgroup',
                Field('name', length=255))

db.define_table('member',
                Field('mgroup', db.mgroup),
                Field('generic', db.generic))

db.artist.path.requires = [IS_NOT_EMPTY(), IS_NOT_IN_DB(db, 'artist.path')]
db.artist.generic.requires = IS_IN_DB(db, 'generic.id', 'generic.id')

db.album.path.requires = [IS_NOT_EMPTY(), IS_NOT_IN_DB(db, 'album.path')]
db.album.generic.requires = IS_IN_DB(db, 'generic.id', 'generic.id')
db.album.artist.requires = IS_IN_DB(db, 'artist.id', 'artist.path')

db.musicfile.path.requires = [IS_NOT_EMPTY(), IS_NOT_IN_DB(db, 'musicfile.path')]
db.musicfile.generic.requires = IS_IN_DB(db, 'generic.id', 'generic.id')
db.musicfile.album.requires = IS_IN_DB(db, 'album.id', 'album.path')
db.musicfile.artist.requires = IS_IN_DB(db, 'artist.id', 'artist.path')

db.played.datetime.requires = IS_DATETIME()
db.played.generic.requires = IS_IN_DB(db, 'generic.id', 'generic.id')
# db.played.musicfile.requires = IS_IN_DB(db, 'musicfile.id', 'musicfile.path')

# db.property.musicfile.requires = IS_IN_DB(db, 'musicfile.id', 'musicfile.path')
db.property.name.requires = IS_NOT_EMPTY()
db.property.generic.requires = IS_IN_DB(db, 'generic.id', 'generic.id')

db.mgroup.name.requires = [IS_NOT_EMPTY(), IS_NOT_IN_DB(db, 'mgroup.name')]

db.member.generic.requires = IS_IN_DB(db, 'generic.id', 'generic.id')
db.member.mgroup.requires = IS_IN_DB(db, 'mgroup.id', 'mgroup.name')

