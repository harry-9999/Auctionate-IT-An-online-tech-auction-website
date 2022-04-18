-- MySQL dump 10.13  Distrib 8.0.23, for Win64 (x86_64)
--
-- Host: localhost    Database: cs336project
-- ------------------------------------------------------
-- Server version	8.0.23

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `alert`
--

DROP TABLE IF EXISTS `alert`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alert` (
  `alertID` int NOT NULL AUTO_INCREMENT,
  `user` varchar(50) NOT NULL,
  `message` varchar(500) NOT NULL,
  `read` tinyint DEFAULT '0',
  PRIMARY KEY (`alertID`),
  KEY `alertFK_user_idx` (`user`),
  CONSTRAINT `alertFK_user` FOREIGN KEY (`user`) REFERENCES `users` (`username`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alert`
--

LOCK TABLES `alert` WRITE;
/*!40000 ALTER TABLE `alert` DISABLE KEYS */;
INSERT INTO `alert` VALUES (1,'mark','AUCTION ENDED: Item wasn\'t sold because nobody placed a bid',0),(6,'mark','Your item got sold!',0),(9,'mark','AUCTION ENDED: Didn\'t win item because didn\'t reach the minimum price',0);
/*!40000 ALTER TABLE `alert` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auction`
--

DROP TABLE IF EXISTS `auction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auction` (
  `auctionID` int unsigned NOT NULL AUTO_INCREMENT,
  `seller` varchar(50) DEFAULT NULL,
  `item_name` varchar(50) DEFAULT NULL,
  `category` varchar(30) DEFAULT NULL,
  `start_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `close_time` datetime NOT NULL,
  `initial_price` decimal(20,2) NOT NULL,
  `highest_bid` decimal(20,2) DEFAULT '0.00',
  `min_increment` decimal(20,2) DEFAULT '0.00',
  `hidden_min_price` decimal(20,2) DEFAULT NULL,
  `description` varchar(500) NOT NULL,
  `sold` tinyint DEFAULT '0',
  PRIMARY KEY (`auctionID`),
  KEY `auctionFK_seller_idx` (`seller`),
  CONSTRAINT `auctionFK_seller` FOREIGN KEY (`seller`) REFERENCES `users` (`username`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auction`
--

LOCK TABLES `auction` WRITE;
/*!40000 ALTER TABLE `auction` DISABLE KEYS */;
INSERT INTO `auction` VALUES (1,'mark','A New Laptop','Desktop Computers','2021-04-25 22:17:39','2021-04-30 23:17:00',200.00,0.00,0.01,0.00,'Brand spanking new laptop! Cheap price',0),(7,'mark','New Phone','Mobile Phones','2021-04-25 22:59:39','2021-04-26 00:00:00',50.00,52.00,0.01,0.00,'new phone',0),(8,'mark','Test','Desktop Computers','2021-04-25 23:01:35','2021-04-26 23:02:00',200.00,0.00,0.01,0.00,'ff',1),(9,'mark','Test2','Desktop Computers','2021-04-25 23:01:58','2021-04-27 00:02:00',200.00,202.00,0.01,0.00,'',1);
/*!40000 ALTER TABLE `auction` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `SoldItems` AFTER UPDATE ON `auction` FOR EACH ROW IF NEW.sold=true THEN
	BEGIN
		IF OLD.highest_bid > OLD.hidden_min_price THEN
			# inserts the item into the buying history table
			INSERT INTO buyhistory (auctionID, buyer, priceBought, dateBought)
			SELECT B.auctionId, B.buyer, B.bid_amount, NOW()
			FROM bid B
			WHERE B.auctionID=NEW.auctionID;

			# alert for the seller
			INSERT INTO alert (user, message)
			SELECT A.seller, "Your item got sold!"
			FROM auction A
			WHERE A.auctionID=NEW.auctionID;

			# alert for the buyer
			INSERT INTO alert (user, message)
			SELECT B.buyer, "You've got the item!"
			FROM Bid B
			WHERE B.auctionID=NEW.auctionID;

			# removes the bids for the item after it's sold
			DELETE FROM bid WHERE auctionID=NEW.auctionID;
		ELSE IF OLD.highest_bid < OLD.hidden_min_price THEN
			# alert for the seller
			INSERT INTO alert (user, message)
			SELECT A.seller, "AUCTION ENDED: Item wasn't sold because didn't reach the minimum price"
			FROM auction A
			WHERE A.auctionID=NEW.auctionID;

			# alert for the buyer
			INSERT INTO alert (user, message)
			SELECT B.buyer, "AUCTION ENDED: Didn't win item because didn't reach the minimum price"
			FROM Bid B
			WHERE B.auctionID=NEW.auctionID;
			# removes the bids for the item after it's sold
			DELETE FROM bid WHERE auctionID=NEW.auctionID;
		ELSE
			# alert for the seller
			INSERT INTO alert (user, message)
			SELECT A.seller, "AUCTION ENDED: Item wasn't sold because nobody placed a bid"
			FROM auction A
			WHERE A.auctionID=NEW.auctionID;
		END IF;
	END IF;
    END;
END IF */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `autobid`
--

DROP TABLE IF EXISTS `autobid`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `autobid` (
  `user` varchar(50) NOT NULL,
  `auctionID` int NOT NULL,
  `max_price` decimal(20,2) NOT NULL,
  `bid_increment` decimal(20,2) NOT NULL,
  PRIMARY KEY (`user`,`auctionID`),
  CONSTRAINT `autobidFK_user` FOREIGN KEY (`user`) REFERENCES `users` (`username`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `autobid`
--

LOCK TABLES `autobid` WRITE;
/*!40000 ALTER TABLE `autobid` DISABLE KEYS */;
/*!40000 ALTER TABLE `autobid` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bid`
--

DROP TABLE IF EXISTS `bid`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bid` (
  `bidID` int NOT NULL AUTO_INCREMENT,
  `auctionID` int DEFAULT NULL,
  `bid_amount` float NOT NULL,
  `time_of_bid` datetime DEFAULT CURRENT_TIMESTAMP,
  `buyer` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`bidID`),
  UNIQUE KEY `bidID_UNIQUE` (`bidID`),
  KEY `bidFK_buyer_idx` (`buyer`),
  CONSTRAINT `bidFK_buyer` FOREIGN KEY (`buyer`) REFERENCES `users` (`username`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bid`
--

LOCK TABLES `bid` WRITE;
/*!40000 ALTER TABLE `bid` DISABLE KEYS */;
/*!40000 ALTER TABLE `bid` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bidhistory`
--

DROP TABLE IF EXISTS `bidhistory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bidhistory` (
  `auctionID` int NOT NULL,
  `buyer` varchar(50) DEFAULT NULL,
  `bid` decimal(20,2) NOT NULL,
  `time_of_bid` datetime DEFAULT NULL,
  PRIMARY KEY (`auctionID`,`bid`),
  KEY `bidhistoryFK_buyer_idx` (`buyer`),
  CONSTRAINT `bidhistoryFK_buyer` FOREIGN KEY (`buyer`) REFERENCES `users` (`username`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bidhistory`
--

LOCK TABLES `bidhistory` WRITE;
/*!40000 ALTER TABLE `bidhistory` DISABLE KEYS */;
/*!40000 ALTER TABLE `bidhistory` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `buyhistory`
--

DROP TABLE IF EXISTS `buyhistory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `buyhistory` (
  `auctionID` int NOT NULL,
  `buyer` varchar(45) DEFAULT NULL,
  `priceBought` decimal(20,2) NOT NULL,
  `dateBought` datetime DEFAULT NULL,
  PRIMARY KEY (`auctionID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `buyhistory`
--

LOCK TABLES `buyhistory` WRITE;
/*!40000 ALTER TABLE `buyhistory` DISABLE KEYS */;
INSERT INTO `buyhistory` VALUES (9,'hello',202.00,'2021-04-25 23:04:20');
/*!40000 ALTER TABLE `buyhistory` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `userID` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `first_name` varchar(45) NOT NULL,
  `last_name` varchar(45) NOT NULL,
  `usertype` varchar(15) DEFAULT 'customer',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `is_admin` tinyint DEFAULT '0',
  `is_rep` tinyint DEFAULT '0',
  PRIMARY KEY (`userID`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `userID_UNIQUE` (`userID`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'mark','wahlberg','Mark','Wahlberg','customer','2021-04-25 21:56:02',0,0),(2,'admin','p@ssw0rd','John','Wick','admin','2021-04-25 21:57:05',1,0),(3,'helper','h3lpm3','Billy','Fischer','cust_rep','2021-04-25 21:58:03',0,1);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `CancelAutoBid` BEFORE DELETE ON `users` FOR EACH ROW BEGIN
	DELETE FROM autobid WHERE user=OLD.username;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2021-04-25 23:14:02
