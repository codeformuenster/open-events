-- MySQL dump 10.13  Distrib 5.5.43, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: msterm
-- ------------------------------------------------------
-- Server version	5.5.43-0ubuntu0.14.10.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `event`
--

DROP TABLE IF EXISTS `event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event` (
  `event_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `location_id` int(10) unsigned NOT NULL,
  `location_source_id` mediumint(8) unsigned DEFAULT NULL,
  `featured` tinyint(4) NOT NULL DEFAULT '0',
  `active` tinyint(4) NOT NULL DEFAULT '1',
  `event_title` varchar(255) NOT NULL,
  `event_datetime` datetime NOT NULL,
  `event_enddate` datetime DEFAULT NULL,
  `event_link` varchar(500) DEFAULT NULL,
  `event_image` varchar(500) DEFAULT NULL,
  `event_type` varchar(30) DEFAULT NULL,
  `event_md5` varchar(33) NOT NULL,
  `event_description` text,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`event_id`),
  UNIQUE KEY `event_md5` (`event_md5`),
  KEY `fk_location_id` (`location_id`),
  KEY `featured_index` (`featured`),
  KEY `active_index` (`active`),
  CONSTRAINT `fk_location_id` FOREIGN KEY (`location_id`) REFERENCES `location` (`location_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=393534 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `event_import_stats`
--

DROP TABLE IF EXISTS `event_import_stats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_import_stats` (
  `import_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `import_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `location_source_id` int(10) unsigned NOT NULL,
  `found_events` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `new_events` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `updated_events` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `error_events` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `error_message` text,
  PRIMARY KEY (`import_id`),
  KEY `location_idsne` (`location_source_id`),
  CONSTRAINT `location_idsne` FOREIGN KEY (`location_source_id`) REFERENCES `location_source` (`source_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=31316 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `location`
--

DROP TABLE IF EXISTS `location`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `location` (
  `location_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `active` tinyint(4) DEFAULT '1',
  `location_name` varchar(255) NOT NULL DEFAULT '',
  `location_type` varchar(30) DEFAULT NULL,
  `location_url` varchar(255) NOT NULL DEFAULT '',
  `musikrichtung` varchar(50) DEFAULT NULL,
  `tags` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `city` varchar(30) DEFAULT NULL,
  `zip` varchar(12) DEFAULT NULL,
  `longitude` decimal(12,9) DEFAULT NULL,
  `latitude` decimal(12,9) DEFAULT NULL,
  `location_desc` mediumtext NOT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_date` datetime DEFAULT NULL,
  PRIMARY KEY (`location_id`),
  KEY `location_type` (`location_type`)
) ENGINE=InnoDB AUTO_INCREMENT=275 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `location_3rd_party_data`
--

DROP TABLE IF EXISTS `location_3rd_party_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `location_3rd_party_data` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `location_id` int(10) unsigned DEFAULT NULL,
  `data_source` varchar(50) NOT NULL,
  `3rd_party_location_name` varchar(255) NOT NULL DEFAULT '',
  `3rd_party_query` varchar(255) DEFAULT NULL,
  `3rd_party_id` varchar(255) DEFAULT NULL,
  `3rd_party_data` text NOT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `location_id` (`location_id`),
  CONSTRAINT `location_id_3rd` FOREIGN KEY (`location_id`) REFERENCES `location` (`location_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=233 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `location_source`
--

DROP TABLE IF EXISTS `location_source`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `location_source` (
  `source_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `location_id` int(10) unsigned NOT NULL,
  `active` tinyint(4) DEFAULT '1',
  `source_url` varchar(255) NOT NULL DEFAULT '',
  `source_type` varchar(30) DEFAULT NULL,
  `parser` varchar(255) DEFAULT NULL,
  `default_event_type` varchar(255) DEFAULT '',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_date` datetime DEFAULT NULL,
  PRIMARY KEY (`source_id`),
  UNIQUE KEY `location_id` (`location_id`,`source_url`),
  CONSTRAINT `location_id` FOREIGN KEY (`location_id`) REFERENCES `location` (`location_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `location_time`
--

DROP TABLE IF EXISTS `location_time`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `location_time` (
  `time_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `location_id` int(10) unsigned NOT NULL,
  `what` varchar(50) NOT NULL DEFAULT '',
  `timeframe` text,
  `description` text,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_date` datetime DEFAULT NULL,
  PRIMARY KEY (`time_id`),
  KEY `location_idsn` (`location_id`),
  CONSTRAINT `location_idsn` FOREIGN KEY (`location_id`) REFERENCES `location` (`location_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `website`
--

DROP TABLE IF EXISTS `website`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `website` (
  `website_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `website_url` varchar(255) NOT NULL,
  `website_title` varchar(255) NOT NULL,
  `website_desc` varchar(255) NOT NULL,
  `website_tags` varchar(255) DEFAULT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`website_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-09-21 10:23:32
