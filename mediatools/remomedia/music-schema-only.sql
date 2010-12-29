-- MySQL Administrator dump 1.4
--
-- ------------------------------------------------------
-- Server version	5.0.51a-3ubuntu5.4


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


--
-- Create schema music
--

CREATE DATABASE IF NOT EXISTS music;
USE music;

--
-- Definition of table `music`.`musicfile`
--

DROP TABLE IF EXISTS `music`.`musicfile`;
CREATE TABLE  `music`.`musicfile` (
  `id` int(11) NOT NULL auto_increment,
  `path` varchar(255) default NULL,
  `freq` double default NULL,
  `freq_history` double default NULL,
  `play_count` int(11) default NULL,
  `file_exists` int(11) default NULL,
  `trackname` varchar(255) default NULL,
  `artist` varchar(255) default NULL,
  `seconds` int(11) default NULL,
  `vbr` int(11) default NULL,
  `filesize` int(11) default NULL,
  `bitrate` int(11) default NULL,
  `notes` longtext,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2686 DEFAULT CHARSET=utf8;

/*!40000 ALTER TABLE `musicfile` ENABLE KEYS */;

--
-- Definition of table `music`.`played`
--

DROP TABLE IF EXISTS `music`.`played`;
CREATE TABLE  `music`.`played` (
  `id` int(11) NOT NULL auto_increment,
  `musicfile` int(11) default NULL,
  `kind` varchar(10) default NULL,
  `datetime` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `musicfile__idx` (`musicfile`),
  CONSTRAINT `played_ibfk_1` FOREIGN KEY (`musicfile`) REFERENCES `musicfile` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5476 DEFAULT CHARSET=utf8;

/*!40000 ALTER TABLE `played` ENABLE KEYS */;


--
-- Definition of table `music`.`property`
--

DROP TABLE IF EXISTS `music`.`property`;
CREATE TABLE  `music`.`property` (
  `id` int(11) NOT NULL auto_increment,
  `musicfile` int(11) default NULL,
  `name` varchar(50) default NULL,
  `value` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `musicfile__idx` (`musicfile`),
  CONSTRAINT `property_ibfk_1` FOREIGN KEY (`musicfile`) REFERENCES `musicfile` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2115 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `music`.`property`
--

/*!40000 ALTER TABLE `property` ENABLE KEYS */;


/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
