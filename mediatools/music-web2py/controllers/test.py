# coding: utf8
# try something like
def index(): return dict(message="hello nico from test.py")

def musicfiles_all():
    records = db().select(db.musicfile.ALL, orderby=db.musicfile.trackname)
    return dict(records=SQLTABLE(records))

# straks ook like proberen.
def musicfiles():
    if request.vars.trackname==None:
        request.vars.trackname='ZZZ'
    records=db(db.musicfile.trackname.like(request.vars.trackname))\
        .select(orderby=db.musicfile.trackname)
    form = SQLFORM(db.musicfile, fields=['trackname'])
    return dict(form=form,records=records)
    
def show():
    id=request.vars.id
    mfs = db(db.musicfile.id==id).select()
    if not len(mfs): redirect(URL(r=request,f='musicfiles'))
    return dict(musicfile=mfs[0])
    
def new_musicfile():
    form=SQLFORM(db.musicfile, fields=['path','artist',\
        'trackname','freq', 'seconds', 'filesize', 'bitrate'])
    if form.accepts(request.vars, session):
        redirect(URL(r=request,f='musicfiles'))
    return dict(form=form)
