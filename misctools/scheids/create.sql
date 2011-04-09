  CREATE DATABASE IF NOT EXISTS scheids;
  USE scheids;
  
  CREATE TABLE  `scheids`.`team` (
    `id` int(11) NOT NULL auto_increment,
    `naam` varchar(10) default NULL,
    `scheids_nodig` int(11) default NULL,
    `opmerkingen` varchar(255) default NULL,
    PRIMARY KEY  (`id`)
  ) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
  
  CREATE TABLE  `scheids`.`persoon` (
    `id` int(11) NOT NULL auto_increment,
    `naam` varchar(255) default NULL,
    `email` varchar(255) default NULL,
    `telnrs` varchar(255) default NULL,
    `speelt_in` int(11) default NULL,
    `opmerkingen` varchar(255) default NULL,
    `nevobocode` varchar(10) default NULL,
    PRIMARY KEY  (`id`),
    KEY `speelt_in__idx` (`speelt_in`),
    CONSTRAINT `persoon_ibfk_1` FOREIGN KEY (`speelt_in`) REFERENCES `team` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8;
  
  CREATE TABLE  `scheids`.`wedstrijd` (
    `id` int(11) NOT NULL auto_increment,
    `team` int(11) default NULL,
    `lokatie` varchar(10) default NULL,
    `datumtijd` datetime default NULL,
    `scheids_nodig` int(11) default NULL,
    `opmerkingen` varchar(255) default NULL,
    `naam` varchar(255) default NULL,
    `date_inserted` datetime default NULL,
    `date_checked` datetime default NULL,
    PRIMARY KEY  (`id`),
    KEY `team__idx` (`team`),
    CONSTRAINT `wedstrijd_ibfk_1` FOREIGN KEY (`team`) REFERENCES `team` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB AUTO_INCREMENT=138 DEFAULT CHARSET=utf8;
  
  CREATE TABLE  `scheids`.`afwezig` (
    `id` int(11) NOT NULL auto_increment,
    `persoon` int(11) default NULL,
    `eerstedag` date default NULL,
    `laatstedag` date default NULL,
    `opmerkingen` varchar(255) default NULL,
    PRIMARY KEY  (`id`),
    KEY `persoon__idx` (`persoon`),
    CONSTRAINT `afwezig_ibfk_1` FOREIGN KEY (`persoon`) REFERENCES `persoon` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
  
  CREATE TABLE  `scheids`.`kan_team_fluiten` (
    `id` int(11) NOT NULL auto_increment,
    `scheids` int(11) default NULL,
    `team` int(11) default NULL,
    `waarde` double default NULL,
    `opmerkingen` varchar(255) default NULL,
    PRIMARY KEY  (`id`),
    KEY `scheids__idx` (`scheids`),
    KEY `team__idx` (`team`),
    CONSTRAINT `kan_team_fluiten_ibfk_1` FOREIGN KEY (`scheids`) REFERENCES `persoon` (`id`) ON DELETE CASCADE,
    CONSTRAINT `kan_team_fluiten_ibfk_2` FOREIGN KEY (`team`) REFERENCES `team` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB AUTO_INCREMENT=112 DEFAULT CHARSET=utf8;
  
  CREATE TABLE  `scheids`.`kan_wedstrijd_fluiten` (
    `id` int(11) NOT NULL auto_increment,
    `scheids` int(11) default NULL,
    `wedstrijd` int(11) default NULL,
    `waarde` double default NULL,
    `speelt_zelfde_dag` int(11) default NULL,
    `opmerkingen` varchar(255) default NULL,
    `date_inserted` datetime default NULL,
    PRIMARY KEY  (`id`),
    KEY `scheids__idx` (`scheids`),
    KEY `wedstrijd__idx` (`wedstrijd`),
    CONSTRAINT `kan_wedstrijd_fluiten_ibfk_1` FOREIGN KEY (`scheids`) REFERENCES `persoon` (`id`) ON DELETE CASCADE,
    CONSTRAINT `kan_wedstrijd_fluiten_ibfk_2` FOREIGN KEY (`wedstrijd`) REFERENCES `wedstrijd` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB AUTO_INCREMENT=704 DEFAULT CHARSET=utf8;
  
  CREATE TABLE  `scheids`.`persoon_team` (
    `id` int(11) NOT NULL auto_increment,
    `persoon` int(11) default NULL,
    `team` int(11) default NULL,
    `soort` varchar(40) default NULL,
    PRIMARY KEY  (`id`),
    KEY `persoon__idx` (`persoon`),
    KEY `team__idx` (`team`),
    CONSTRAINT `persoon_team_ibfk_1` FOREIGN KEY (`persoon`) REFERENCES `persoon` (`id`) ON DELETE CASCADE,
    CONSTRAINT `persoon_team_ibfk_2` FOREIGN KEY (`team`) REFERENCES `team` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8;
  
  CREATE TABLE  `scheids`.`scheids` (
    `id` int(11) NOT NULL auto_increment,
    `scheids` int(11) default NULL,
    `wedstrijd` int(11) default NULL,
    `speelt_zelfde_dag` int(11) default NULL,
    `opmerkingen` varchar(255) default NULL,
    `date_inserted` datetime default NULL,
    `status` varchar(20) default NULL,
    `waarde` double default NULL,
    PRIMARY KEY  (`id`),
    KEY `scheids__idx` (`scheids`),
    KEY `wedstrijd__idx` (`wedstrijd`),
    CONSTRAINT `scheids_ibfk_1` FOREIGN KEY (`scheids`) REFERENCES `persoon` (`id`) ON DELETE CASCADE,
    CONSTRAINT `scheids_ibfk_2` FOREIGN KEY (`wedstrijd`) REFERENCES `wedstrijd` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB AUTO_INCREMENT=735 DEFAULT CHARSET=utf8;
  
  
  
  CREATE TABLE  `scheids`.`zeurfactor` (
    `id` int(11) NOT NULL auto_increment,
    `persoon` int(11) default NULL,
    `speelt_zelfde_dag` int(11) default NULL,
    `factor` double default NULL,
    `opmerkingen` varchar(255) default NULL,
    PRIMARY KEY  (`id`),
    KEY `persoon__idx` (`persoon`),
    CONSTRAINT `zeurfactor_ibfk_1` FOREIGN KEY (`persoon`) REFERENCES `persoon` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8;

  CREATE TABLE `scheids`.`logsolution` (
    `id` int(11) NOT NULL auto_increment,
    `iteration` int(11) default null,
    `solnr` int(11) default null,
    `solnrparent` int(11) default null,
    `fitness` double default null,
    PRIMARY KEY (`id`)
  )
  
