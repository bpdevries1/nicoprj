drop table if exists bestand;
drop table if exists query;
drop table if exists tabel;
drop table if exists query_tabel;


create table bestand (
  id integer NOT NULL auto_increment,
  path varchar(1023),
  UNIQUE KEY `id` (`id`) 
);


create table query (
  id integer NOT NULL auto_increment,
  naam varchar(255),
  soort varchar(30),
  sqltekst varchar(1023),
  bestand_id integer,
  volgnr integer,
  regelnr integer,
  UNIQUE KEY `id` (`id`) 
);


create table tabel (
  id integer NOT NULL auto_increment,
  naam varchar(1023),
  bestand_id integer,
  UNIQUE KEY `id` (`id`) 
);

create table query_tabel (
  id integer NOT NULL auto_increment,
  soort varchar(10),
  query_id integer,
  tabel_id integer,
  UNIQUE KEY `id` (`id`) 
);
