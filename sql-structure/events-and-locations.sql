
--
-- Table structure for table `event`
--

DROP TABLE IF EXISTS `event`;
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
);

--
-- Table structure for table `location`
--

DROP TABLE IF EXISTS `location`;
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
);

