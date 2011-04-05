CREATE TABLE `result` (
  `form` varchar(200) NOT NULL,
  `questionid` varchar(50) NOT NULL default '',
  `answer` varchar(255) default NULL,
  `location` varchar(45) default NULL,
  `date` date NOT NULL,
  `taker` varchar(45) NOT NULL,
  PRIMARY KEY `rpk` (`form`,`questionid`,`answer`,`date`,`taker`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
