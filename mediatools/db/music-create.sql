-- DROP TABLE IF EXISTS generic;
CREATE TABLE generic (
  id SERIAL,
  gentype varchar(20) DEFAULT NULL,
  freq NUMERIC DEFAULT NULL,
  freq_history NUMERIC DEFAULT NULL,
  play_count int DEFAULT NULL,
PRIMARY KEY (id)
)

-- DROP TABLE IF EXISTS artist;
CREATE TABLE artist (
  id SERIAL,
  generic int DEFAULT NULL,
  path varchar(255) DEFAULT NULL,
  name varchar(255) DEFAULT NULL,
  notes TEXT,
  PRIMARY KEY (id),
  CONSTRAINT artist_ibfk_1 FOREIGN KEY (generic) REFERENCES generic (id) ON DELETE CASCADE
)

-- DROP TABLE IF EXISTS album;
CREATE TABLE album (
  id SERIAL,
  generic int DEFAULT NULL,
  path varchar(255) DEFAULT NULL,
  artist int DEFAULT NULL,
  name varchar(255) DEFAULT NULL,
  notes TEXT,
  PRIMARY KEY (id),
  CONSTRAINT album_ibfk_1 FOREIGN KEY (generic) REFERENCES generic (id) ON DELETE CASCADE,
  CONSTRAINT album_ibfk_2 FOREIGN KEY (artist) REFERENCES artist (id) ON DELETE CASCADE
)

-- DROP TABLE IF EXISTS cassette;
CREATE TABLE cassette (
  id int DEFAULT NULL,
  bandnr varchar(10) DEFAULT NULL,
  titel varchar(255) DEFAULT NULL,
  artiest varchar(255) DEFAULT NULL,
  notes varchar(255) DEFAULT NULL
)

-- DROP TABLE IF EXISTS mgroup;
CREATE TABLE mgroup (
  id SERIAL,
  name varchar(255) DEFAULT NULL,
  PRIMARY KEY (id)
)

-- DROP TABLE IF EXISTS member;
CREATE TABLE member (
  id SERIAL,
  mgroup int DEFAULT NULL,
  generic int DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT member_ibfk_1 FOREIGN KEY (mgroup) REFERENCES mgroup (id) ON DELETE CASCADE,
  CONSTRAINT member_ibfk_2 FOREIGN KEY (generic) REFERENCES generic (id) ON DELETE CASCADE
)

-- DROP TABLE IF EXISTS musicfile;
CREATE TABLE musicfile (
  id SERIAL,
  path varchar(255) DEFAULT NULL,
  file_exists int DEFAULT NULL,
  trackname varchar(255) DEFAULT NULL,
  seconds int DEFAULT NULL,
  vbr int DEFAULT NULL,
  filesize int DEFAULT NULL,
  bitrate int DEFAULT NULL,
  notes TEXT,
  generic int DEFAULT NULL,
  album int DEFAULT NULL,
  artistname varchar(255) DEFAULT NULL,
  artist int DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT musicfile_ibfk_1 FOREIGN KEY (generic) REFERENCES generic (id) ON DELETE CASCADE,
  CONSTRAINT musicfile_ibfk_2 FOREIGN KEY (album) REFERENCES album (id) ON DELETE CASCADE,
  CONSTRAINT musicfile_ibfk_3 FOREIGN KEY (artist) REFERENCES artist (id) ON DELETE CASCADE
)

-- DROP TABLE IF EXISTS played;
CREATE TABLE played (
  id SERIAL,
  kind varchar(10) DEFAULT NULL,
  datetime TIMESTAMP DEFAULT NULL,
  generic int DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT played_ibfk_2 FOREIGN KEY (generic) REFERENCES generic (id) ON DELETE CASCADE
)

-- DROP TABLE IF EXISTS property;
CREATE TABLE property (
  id SERIAL,
  name varchar(50) DEFAULT NULL,
  value varchar(255) DEFAULT NULL,
  generic int DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT property_ibfk_2 FOREIGN KEY (generic) REFERENCES generic (id) ON DELETE CASCADE
)

-- All views at the end.

-- DROP TABLE IF EXISTS albumgen;
CREATE VIEW albumgen AS
select a.id AS id, a.generic AS generic, a.path AS path,
       a.artist AS artist, a.name AS name, a.notes AS notes,
       g.id AS g_id, g.play_count AS play_count,
       g.freq AS freq,g. freq_history AS freq_history,
       g.gentype AS gentype
from album a
join generic g on a.generic = g.id;

-- TODO all below:

-- DROP TABLE IF EXISTS albums;
CREATE VIEW albums AS
select g.id AS id, a.path AS path, g.freq AS freq,
       g.freq_history AS freq_history, g.play_count AS play_count
from generic g
join album a on a.generic = g.id
join member mem on mem.generic = g.id
join mgroup mg on mem.mgroup = mg.id
where mg.name = 'Albums';

CREATE VIEW singles AS
select g.id AS id, a.path AS path, g.freq AS freq,
       g.freq_history AS freq_history, g.play_count AS play_count
from generic g
join album a on a.generic = g.id
join member mem on mem.generic = g.id
join mgroup mg on mem.mgroup = mg.id
where mg.name = 'Singles';

-- indexes
CREATE INDEX ix_generic_id on generic (id);
CREATE INDEX ix_artist_id on artist (id);
CREATE INDEX ix_artist_generic on artist (generic);
CREATE INDEX ix_album_id on album (id);
CREATE INDEX ix_album_generic on album (generic);
CREATE INDEX ix_album_artist on album (artist);
CREATE INDEX ix_cassette_id on cassette (id);
CREATE INDEX ix_mgroup_id on mgroup (id);
CREATE INDEX ix_member_id on member (id);
CREATE INDEX ix_member_mgroup on member (mgroup);
CREATE INDEX ix_member_generic on member (generic);
CREATE INDEX ix_musicfile_id on musicfile (id);
CREATE INDEX ix_musicfile_generic on musicfile (generic);
CREATE INDEX ix_musicfile_album on musicfile (album);
CREATE INDEX ix_musicfile_artist on musicfile (artist);
CREATE INDEX ix_played_id on played (id);
CREATE INDEX ix_played_generic on played (generic);
CREATE INDEX ix_property_id on property (id);
CREATE INDEX ix_property_generic on property (generic);

