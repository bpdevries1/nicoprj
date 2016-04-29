-- kopieer schema.xls naar d:/aaa

drop table speelschema;

create table speelschema (
  groep integer,
  ronde integer,
  veld integer,
  team1a varchar(30),
  team1b varchar(30),
  team2a varchar(30),
  team2b varchar(30),
  scheids varchar(30)
);


LOAD DATA INFILE 'd:/aaa/schema.xls' INTO TABLE speelschema lines terminated by '\r\n' ignore 1 lines;

-- SELECT groep, ronde, veld, concat(team1a, ' / ', team1b) team1, concat(team2a, ' / ', team2b) team2, scheids FROM speelschema s order by groep, ronde, veld;
