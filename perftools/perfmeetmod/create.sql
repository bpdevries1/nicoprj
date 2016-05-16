-- met Web2py creeren?
drop table if exists testrun;
drop table if exists logfile;
drop table if exists resname;
drop table if exists resusage;
drop table if exists task;
drop table if exists machine;
drop table if exists taskdef;

create table testrun (
  id integer NOT NULL auto_increment,
  name varchar(255),
  UNIQUE KEY `id` (`id`) 
);

create table logfile (
  id integer NOT NULL auto_increment,
  testrun_id integer,
  path varchar(255),
  kind varchar(100),
  aantal integer,
  UNIQUE KEY `id` (`id`)
);

create table resname (
  id integer NOT NULL auto_increment,
  fullname varchar(255),
  graphlabel varchar(40),
  tonen integer default 1,
  UNIQUE KEY `id` (`id`)
);

create table resusage (
  id integer NOT NULL auto_increment,
  logfile_id integer,
  linenr integer,
  machine varchar(255),
  resname_id integer,
  value float,
  dt datetime,
  dec_dt decimal(17,3),
  UNIQUE KEY `id` (`id`)
);

create table task (
  id integer NOT NULL auto_increment,
  logfile_id integer,
  threadname varchar(255),
  threadnr integer,
  taskname varchar(255),
  dt_start datetime,
  dt_end datetime,
  sec_duration float,
  dec_start decimal(17,3),
  dec_end decimal(17,3),
  details varchar(1023),
  UNIQUE KEY `id` (`id`)
);

create table machine (
  name varchar(40),
  type varchar(40),
  UNIQUE KEY `name` (`name`)
);

create table taskdef (
  taskname varchar(255),
  graphlabel varchar(255)
);

create table testrunprop (
  id integer NOT NULL auto_increment,
  testrun_id integer,
  name varchar(100),
  value varchar(255),
  UNIQUE KEY `id` (`id`)
);

-- verdere indexen op oa dt_start en dt_end
-- 24-6-2010 toch niet zo nodig.
-- ALTER TABLE `testmeetmod`.`task` ADD INDEX `Index_2`(`dt_start`, `dt_end`);

-- grafiek info bewaren voor correlatie bij klikken.
create table graph (
  id integer NOT NULL auto_increment,
  path varchar(255),
  UNIQUE KEY `id` (`id`)
);

create table task_graph (
  id integer NOT NULL auto_increment,
  task_id integer,
  graph_id integer,
  tag integer,
  UNIQUE KEY `id` (`id`)
);


