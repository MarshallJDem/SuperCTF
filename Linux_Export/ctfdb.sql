-- phpMyAdmin SQL Dump
-- version 4.9.0.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 24, 2019 at 09:13 PM
-- Server version: 10.3.15-MariaDB
-- PHP Version: 7.3.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `ctfdb`
--

-- --------------------------------------------------------

--
-- Table structure for table `matches`
--

CREATE TABLE `matches` (
  `matchID` int(11) NOT NULL,
  `serverIP` varchar(30) NOT NULL,
  `players` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `serverPublicToken` varchar(30) NOT NULL,
  `winningTeamID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `matches`
--

INSERT INTO `matches` (`matchID`, `serverIP`, `players`, `serverPublicToken`, `winningTeamID`) VALUES
(30, '24.15.0.98:42402', '[64,63]', 'RANDOMTOKEN', NULL),
(31, '24.15.0.98:42402', '[66,65]', 'RANDOMTOKEN', NULL),
(32, '24.15.0.98:42402', '[68,67]', 'RANDOMTOKEN', 0),
(33, '24.15.0.98:42402', '[68,69]', 'RANDOMTOKEN', 1),
(34, '24.15.0.98:42402', '[71,70]', 'RANDOMTOKEN', 1),
(35, '24.15.0.98:42402', '[70,71]', 'RANDOMTOKEN', 0),
(36, '24.15.0.98:42402', '[71,72]', 'RANDOMTOKEN', 0),
(37, '24.15.0.98:42402', '[71,72]', 'RANDOMTOKEN', 0),
(38, '24.15.0.98:42402', '[71,72]', 'RANDOMTOKEN', NULL),
(39, '24.15.0.98:42402', '[72,71]', 'RANDOMTOKEN', 1),
(40, '24.15.0.98:42402', '[71,72]', 'RANDOMTOKEN', 1),
(41, '24.15.0.98:42402', '[71,72]', 'RANDOMTOKEN', NULL),
(42, '24.15.0.98:42402', '[74,73]', 'RANDOMTOKEN', NULL),
(43, '24.15.0.98:42402', '[73,72,74]', 'RANDOMTOKEN', 0),
(44, '24.15.0.98:42402', '[72,73,74]', 'RANDOMTOKEN', 0),
(45, '24.15.0.98:42402', '[73,72]', 'RANDOMTOKEN', 1),
(46, '24.15.0.98:42402', '[72,73]', 'RANDOMTOKEN', NULL),
(47, '24.15.0.98:42402', '[73,72,75]', 'RANDOMTOKEN', 1),
(48, '24.15.0.98:42402', '[75,73,76,77]', 'RANDOMTOKEN', 1),
(49, '24.15.0.98:42402', '[73,75,77,76]', 'RANDOMTOKEN', 1),
(50, '24.15.0.98:42402', '[79,78]', 'RANDOMTOKEN', 0),
(51, '24.15.0.98:42402', '[81,80]', 'RANDOMTOKEN', NULL),
(52, '24.15.0.98:42402', '[83,82]', 'RANDOMTOKEN', 1),
(53, '24.15.0.98:42402', '[84,83]', 'RANDOMTOKEN', NULL),
(54, '24.15.0.98:42402', '[87,86]', 'RANDOMTOKEN', NULL),
(55, '24.15.0.98:42402', '[91,90]', 'RANDOMTOKEN', NULL),
(56, '24.15.0.98:42402', '[93,92]', 'RANDOMTOKEN', NULL),
(57, '24.15.0.98:42402', '[95,94]', 'RANDOMTOKEN', NULL),
(58, '24.15.0.98:42402', '[97,96]', 'RANDOMTOKEN', NULL),
(59, '24.15.0.98:42402', '[98,97]', 'RANDOMTOKEN', NULL),
(60, '24.15.0.98:42402', '[99,98]', 'RANDOMTOKEN', NULL),
(61, '24.15.0.98:42402', '[100,99]', 'RANDOMTOKEN', NULL),
(62, '24.15.0.98:42402', '[101,100]', 'RANDOMTOKEN', NULL),
(63, '24.15.0.98:42402', '[102,101]', 'RANDOMTOKEN', NULL),
(64, '24.15.0.98:42402', '[103,102]', 'RANDOMTOKEN', NULL),
(65, '24.15.0.98:42402', '[105,104]', 'RANDOMTOKEN', 1),
(66, '24.15.0.98:42402', '[107,106]', 'RANDOMTOKEN', NULL),
(67, '24.15.0.98:42402', '[109,108]', 'RANDOMTOKEN', NULL),
(68, '24.15.0.98:42402', '[111,110]', 'RANDOMTOKEN', NULL),
(69, '24.15.0.98:42402', '[112,111]', 'RANDOMTOKEN', NULL),
(70, '24.15.0.98:42402', '[113,112]', 'RANDOMTOKEN', NULL),
(71, '24.15.0.98:42402', '[114,104]', 'RANDOMTOKEN', 1),
(72, '24.15.0.98:42402', '[116,115]', 'RANDOMTOKEN', NULL),
(73, '24.15.0.98:42402', '[118,117]', 'RANDOMTOKEN', 0),
(74, '24.15.0.98:42402', '[120,121]', 'RANDOMTOKEN', NULL),
(75, '24.15.0.98:42402', '[125,124]', 'RANDOMTOKEN', 0),
(76, '24.15.0.98:42402', '[127,126]', 'RANDOMTOKEN', NULL),
(77, '24.15.0.98:42402', '[129,128]', 'RANDOMTOKEN', NULL),
(78, '24.15.0.98:42402', '[131,130]', 'RANDOMTOKEN', NULL),
(79, '24.15.0.98:42402', '[133,132]', 'RANDOMTOKEN', NULL),
(80, '24.15.0.98:42402', '[134,133]', 'RANDOMTOKEN', NULL),
(81, '24.15.0.98:42402', '[136,135]', 'RANDOMTOKEN', NULL),
(82, '24.15.0.98:42402', '[138,137]', 'RANDOMTOKEN', NULL),
(83, '24.15.0.98:42402', '[140,139]', 'RANDOMTOKEN', NULL),
(84, '24.15.0.98:42402', '[141,140]', 'RANDOMTOKEN', NULL),
(85, '24.15.0.98:42402', '[143,142]', 'RANDOMTOKEN', NULL),
(86, '24.15.0.98:42402', '[144,145]', 'RANDOMTOKEN', NULL),
(87, '24.15.0.98:42402', '[146,147]', 'RANDOMTOKEN', NULL),
(88, '24.15.0.98:42402', '[148,149]', 'RANDOMTOKEN', NULL),
(89, '24.15.0.98:42402', '[150,151]', 'RANDOMTOKEN', NULL),
(90, '24.15.0.98:42402', '[152,153]', 'RANDOMTOKEN', NULL),
(91, '24.15.0.98:42402', '[154,155]', 'RANDOMTOKEN', NULL),
(92, '24.15.0.98:42402', '[156,157]', 'RANDOMTOKEN', NULL),
(93, '24.15.0.98:42402', '[158,159]', 'RANDOMTOKEN', NULL),
(94, '24.15.0.98:42402', '[160,161]', 'RANDOMTOKEN', NULL),
(95, '24.15.0.98:42402', '[162,163]', 'RANDOMTOKEN', NULL),
(96, '24.15.0.98:42402', '[165,167]', 'RANDOMTOKEN', NULL),
(97, '24.15.0.98:42402', '[180,179]', 'RANDOMTOKEN', NULL),
(98, '24.15.0.98:42402', '[183,182]', 'RANDOMTOKEN', 1),
(99, '24.15.0.98:42402', '[184,185]', 'RANDOMTOKEN', NULL),
(100, '24.15.0.98:42402', '[186,187]', 'RANDOMTOKEN', 1),
(101, '24.15.0.98:42402', '[187,188]', 'RANDOMTOKEN', NULL),
(102, '24.15.0.98:42402', '[190,189]', 'RANDOMTOKEN', NULL),
(103, '24.15.0.98:42402', '[191,189]', 'RANDOMTOKEN', 0),
(104, '24.15.0.98:42402', '[192,190]', 'RANDOMTOKEN', 0),
(105, '24.15.0.98:42402', '[190,192]', 'RANDOMTOKEN', 1),
(106, '24.15.0.98:42402', '[192,193]', 'RANDOMTOKEN', NULL),
(107, '24.15.0.98:42402', '[194,192]', 'RANDOMTOKEN', NULL),
(108, '24.15.0.98:42402', '[197,196]', 'RANDOMTOKEN', NULL),
(109, '24.15.0.98:42402', '[199,198]', 'RANDOMTOKEN', NULL),
(110, '24.15.0.98:42402', '[200,201]', 'RANDOMTOKEN', 1),
(111, '24.15.0.98:42402', '[203,202]', 'RANDOMTOKEN', NULL),
(112, '24.15.0.98:42402', '[207,215]', 'RANDOMTOKEN', NULL),
(113, '24.15.0.98:42402', '[219,218]', 'RANDOMTOKEN', NULL),
(114, '24.15.0.98:42402', '[228,227,229]', 'RANDOMTOKEN', 1),
(115, '24.15.0.98:42402', '[228,227]', 'RANDOMTOKEN', 1),
(116, '24.15.0.98:42402', '[231,230]', 'RANDOMTOKEN', NULL),
(117, '24.15.0.98:42402', '[232,231]', 'RANDOMTOKEN', NULL),
(118, '24.15.0.98:42402', '[233,232]', 'RANDOMTOKEN', NULL),
(119, '24.15.0.98:42402', '[234,233]', 'RANDOMTOKEN', NULL),
(120, '24.15.0.98:42402', '[235,236]', 'RANDOMTOKEN', NULL),
(121, '24.15.0.98:42402', '[237,236]', 'RANDOMTOKEN', NULL),
(122, '24.15.0.98:42402', '[238,237]', 'RANDOMTOKEN', NULL),
(123, '24.15.0.98:42402', '[239,238]', 'RANDOMTOKEN', NULL),
(124, '24.15.0.98:42402', '[240,239]', 'RANDOMTOKEN', NULL),
(125, '24.15.0.98:42402', '[242,240]', 'RANDOMTOKEN', NULL),
(126, '24.15.0.98:42402', '[243,242]', 'RANDOMTOKEN', NULL),
(127, '24.15.0.98:42402', '[244,243]', 'RANDOMTOKEN', NULL),
(128, '24.15.0.98:42402', '[245,246]', 'RANDOMTOKEN', NULL),
(129, '24.15.0.98:42402', '[247,246]', 'RANDOMTOKEN', NULL),
(130, '24.15.0.98:42402', '[248,247]', 'RANDOMTOKEN', NULL),
(131, '24.15.0.98:42402', '[250,249]', 'RANDOMTOKEN', NULL),
(132, '24.15.0.98:42402', '[251,250]', 'RANDOMTOKEN', NULL),
(133, '24.15.0.98:42402', '[251,252]', 'RANDOMTOKEN', NULL),
(134, '24.15.0.98:42402', '[252,253]', 'RANDOMTOKEN', NULL),
(135, '24.15.0.98:42402', '[261,260]', 'RANDOMTOKEN', NULL),
(136, '24.15.0.98:42402', '[262,261]', 'RANDOMTOKEN', NULL),
(137, '24.15.0.98:42402', '[263,262]', 'RANDOMTOKEN', NULL),
(138, '24.15.0.98:42402', '[228,227]', 'RANDOMTOKEN', NULL),
(139, '24.15.0.98:42402', '[265,264]', 'RANDOMTOKEN', 1),
(140, '24.15.0.98:42402', '[266,263]', 'RANDOMTOKEN', NULL),
(141, '24.15.0.98:42402', '[267,266]', 'RANDOMTOKEN', NULL),
(142, '24.15.0.98:42402', '[268,267]', 'RANDOMTOKEN', NULL),
(143, '24.15.0.98:42402', '[270,269]', 'RANDOMTOKEN', NULL),
(144, '24.15.0.98:42402', '[272,270]', 'RANDOMTOKEN', NULL),
(145, '24.15.0.98:42402', '[274,272]', 'RANDOMTOKEN', NULL),
(146, '24.15.0.98:42402', '[276,275]', 'RANDOMTOKEN', NULL),
(147, '24.15.0.98:42402', '[278,277]', 'RANDOMTOKEN', NULL),
(148, '24.15.0.98:42402', '[278,277]', 'RANDOMTOKEN', NULL),
(149, '24.15.0.98:42402', '[278,277]', 'RANDOMTOKEN', NULL),
(150, '24.15.0.98:42402', '[278,279]', 'RANDOMTOKEN', NULL),
(151, '24.15.0.98:42402', '[280,277]', 'RANDOMTOKEN', NULL),
(152, '24.15.0.98:42402', '[281,280]', 'RANDOMTOKEN', NULL),
(153, '24.15.0.98:42402', '[282,281]', 'RANDOMTOKEN', NULL),
(154, '24.15.0.98:42402', '[283,282]', 'RANDOMTOKEN', NULL),
(155, '24.15.0.98:42402', '[287,286]', 'RANDOMTOKEN', NULL),
(156, '24.15.0.98:42402', '[287,278]', 'RANDOMTOKEN', NULL),
(157, '24.15.0.98:42402', '[288,227]', 'RANDOMTOKEN', NULL),
(158, '24.15.0.98:42402', '[289,288]', 'RANDOMTOKEN', NULL),
(159, '24.15.0.98:42402', '[290,289]', 'RANDOMTOKEN', NULL),
(160, '24.15.0.98:42402', '[292,290]', 'RANDOMTOKEN', NULL),
(161, '24.15.0.98:42402', '[293,292]', 'RANDOMTOKEN', NULL),
(162, '24.15.0.98:42402', '[278,294]', 'RANDOMTOKEN', NULL),
(163, '24.15.0.98:42402', '[295,278]', 'RANDOMTOKEN', NULL),
(164, '24.15.0.98:42402', '[295,278]', 'RANDOMTOKEN', NULL),
(165, '24.15.0.98:42402', '[296,295]', 'RANDOMTOKEN', NULL),
(166, '24.15.0.98:42402', '[297,296]', 'RANDOMTOKEN', NULL),
(167, '24.15.0.98:42402', '[298,297]', 'RANDOMTOKEN', NULL),
(168, '24.15.0.98:42402', '[298,278]', 'RANDOMTOKEN', NULL),
(169, '24.15.0.98:42402', '[300,299]', 'RANDOMTOKEN', NULL),
(170, '24.15.0.98:42402', '[301,300]', 'RANDOMTOKEN', NULL),
(171, '24.15.0.98:42402', '[302,301]', 'RANDOMTOKEN', NULL),
(172, '24.15.0.98:42402', '[305,306]', 'RANDOMTOKEN', NULL),
(173, '24.15.0.98:42402', '[279,307]', 'RANDOMTOKEN', NULL),
(174, '24.15.0.98:42402', '[308,309]', 'RANDOMTOKEN', NULL),
(175, '24.15.0.98:42402', '[309,207]', 'RANDOMTOKEN', NULL),
(176, '24.15.0.98:42402', '[309,207]', 'RANDOMTOKEN', 0),
(177, '24.15.0.98:42402', '[309,207]', 'RANDOMTOKEN', 0),
(178, '24.15.0.98:42402', '[309,207]', 'RANDOMTOKEN', NULL),
(179, '24.15.0.98:42402', '[328,327]', 'RANDOMTOKEN', 0),
(180, '24.15.0.98:42402', '[330,327]', 'RANDOMTOKEN', NULL),
(181, '24.15.0.98:42402', '[329,327]', 'RANDOMTOKEN', 1),
(182, '24.15.0.98:42402', '[329,334]', 'RANDOMTOKEN', NULL),
(183, '24.15.0.98:42402', '[336,329]', 'RANDOMTOKEN', 0),
(184, '24.15.0.98:42402', '[336,329]', 'RANDOMTOKEN', 0),
(185, '24.15.0.98:42402', '[336,229]', 'RANDOMTOKEN', 0),
(186, '24.15.0.98:42402', '[229,336]', 'RANDOMTOKEN', NULL),
(187, '24.15.0.98:42402', '[336,229]', 'RANDOMTOKEN', 0),
(188, '24.15.0.98:42402', '[341,340]', 'RANDOMTOKEN', NULL),
(189, '24.15.0.98:42402', '[342,343]', 'RANDOMTOKEN', 0),
(190, '24.15.0.98:42402', '[345,344]', 'RANDOMTOKEN', NULL),
(191, '24.15.0.98:42402', '[347,346]', 'RANDOMTOKEN', NULL),
(192, '24.15.0.98:42402', '[348,349]', 'RANDOMTOKEN', 0),
(193, '24.15.0.98:42402', '[351,348]', 'RANDOMTOKEN', NULL),
(194, '24.15.0.98:42402', '[352,353]', 'RANDOMTOKEN', 1),
(195, '24.15.0.98:42402', '[352,353]', 'RANDOMTOKEN', 1),
(196, '24.15.0.98:42402', '[354,352]', 'RANDOMTOKEN', 0),
(197, '24.15.0.98:42402', '[355,356]', 'RANDOMTOKEN', 1),
(198, '24.15.0.98:42402', '[356,355]', 'RANDOMTOKEN', NULL),
(199, '24.15.0.98:42402', '[357,356]', 'RANDOMTOKEN', 0),
(200, '24.15.0.98:42402', '[359,358]', 'RANDOMTOKEN', NULL),
(201, '24.15.0.98:42402', '[358,359]', 'RANDOMTOKEN', 1),
(202, '24.15.0.98:42402', '[358,361]', 'RANDOMTOKEN', NULL),
(203, '24.15.0.98:42402', '[359,362]', 'RANDOMTOKEN', 1),
(204, '24.15.0.98:42402', '[365,364]', 'RANDOMTOKEN', NULL),
(205, '24.15.0.98:42402', '[367,366]', 'RANDOMTOKEN', NULL),
(206, '24.15.0.98:42402', '[368,369]', 'RANDOMTOKEN', NULL),
(207, '24.15.0.98:42402', '[371,370]', 'RANDOMTOKEN', 0),
(208, '24.15.0.98:42402', '[373,374]', 'RANDOMTOKEN', NULL),
(209, '24.15.0.98:42402', '[375,373]', 'RANDOMTOKEN', 0),
(210, '24.15.0.98:42402', '[376,375]', 'RANDOMTOKEN', 0),
(211, '24.15.0.98:42402', '[376,375]', 'RANDOMTOKEN', NULL),
(212, '24.15.0.98:42402', '[379,375]', 'RANDOMTOKEN', NULL),
(213, '24.15.0.98:42402', '[380,375]', 'RANDOMTOKEN', NULL),
(214, '24.15.0.98:42402', '[381,375]', 'RANDOMTOKEN', NULL),
(215, '24.15.0.98:42402', '[382,375]', 'RANDOMTOKEN', 1),
(216, '24.15.0.98:42402', '[375,384]', 'RANDOMTOKEN', 1),
(217, '24.15.0.98:42402', '[388,387]', 'RANDOMTOKEN', NULL),
(218, '24.15.0.98:42402', '[390,375]', 'RANDOMTOKEN', NULL),
(219, '24.15.0.98:42402', '[393,392]', 'RANDOMTOKEN', 0),
(220, '24.15.0.98:42402', '[396,395]', 'RANDOMTOKEN', NULL),
(221, '24.15.0.98:42402', '[398,397]', 'RANDOMTOKEN', NULL),
(222, '24.15.0.98:42402', '[399,329]', 'RANDOMTOKEN', 0),
(223, '24.15.0.98:42402', '[400,329]', 'RANDOMTOKEN', NULL),
(224, '24.15.0.98:42402', '[402,401]', 'RANDOMTOKEN', NULL),
(225, '24.15.0.98:42402', '[403,402]', 'RANDOMTOKEN', NULL),
(226, '24.15.0.98:42402', '[404,405]', 'RANDOMTOKEN', NULL),
(227, '24.15.0.98:42402', '[406,405]', 'RANDOMTOKEN', NULL),
(228, '24.15.0.98:42402', '[408,406]', 'RANDOMTOKEN', 0),
(229, '24.15.0.98:42402', '[409,410]', 'RANDOMTOKEN', NULL),
(230, '24.15.0.98:42402', '[411,410]', 'RANDOMTOKEN', NULL),
(231, '24.15.0.98:42402', '[412,411]', 'RANDOMTOKEN', NULL),
(232, '127.0.0.1:42402', '[413,412]', 'RANDOMTOKEN', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `parties`
--

CREATE TABLE `parties` (
  `partyHostID` int(11) NOT NULL DEFAULT -1,
  `players` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `players`
--

CREATE TABLE `players` (
  `name` varchar(15) DEFAULT NULL,
  `password` varchar(20) DEFAULT NULL,
  `mmr` int(11) NOT NULL DEFAULT 0,
  `uid` int(11) NOT NULL,
  `token` varchar(50) DEFAULT NULL,
  `type` char(1) NOT NULL DEFAULT 'A',
  `partyHostID` int(11) DEFAULT NULL,
  `status` varchar(50) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `players`
--

INSERT INTO `players` (`name`, `password`, `mmr`, `uid`, `token`, `type`, `partyHostID`, `status`) VALUES
('Guest516', NULL, 0, 122, 'U9tjo2hkwbEpUzAWivvBH4YCZHXFI7E1UzM', 'G', NULL, '0'),
('Guest496', NULL, 0, 123, 'No2-vOOgmS_lNlPCshVV9fsnz4ntaM-zwOw', 'G', NULL, '0'),
('Guest408', NULL, 0, 124, 'j7VHLQP7GA6_kr2zv2rLvCVWO3oAeKUcjqO', 'G', NULL, '0'),
('Guest221', NULL, 0, 125, 'T8_PlEFGqp-cf3DI_bPrWhCuahpwl_SQMMX', 'G', NULL, '0'),
('Guest572', NULL, 0, 126, 'WugB917bNRJ645ZIbDX9x_q6NJ-TCJ0BfyT', 'G', NULL, '0'),
('Guest751', NULL, 0, 127, 'jn2CDooY4wtlfKVvfInwq6ytpSKsCUtc7UZ', 'G', NULL, '0'),
('Guest989', NULL, 0, 128, 'udP6YzlxGygDc5_8KempPtQT4_WO2QlezNB', 'G', NULL, '0'),
('Guest871', NULL, 0, 129, 'th7-OldxB2Y1zMsRVXqzjLHzmDwjrZECrX-', 'G', NULL, '0'),
('Guest83', NULL, 0, 130, 'K4aXzOSn9ByHcTyXtE6Vjjt_3S3-rUprRFU', 'G', NULL, '0'),
('Guest239', NULL, 0, 131, 'XesM0DiU3zhMa2c2L1qwed4Qx22_K5LAwnl', 'G', NULL, '0'),
('Guest672', NULL, 0, 132, 'g-D3_Szt0PGtE7O-cpL49hd8R7OtrjSV_jE', 'G', NULL, '0'),
('Guest713', NULL, 0, 133, 'X3llLsnbW5_EAMYAbPR4p2pZyLgN8QAwu3E', 'G', NULL, '0'),
('Guest954', NULL, 0, 134, 'gUzElf0BYZi7HiNbEEC1qdv8VF01niBvs4l', 'G', NULL, '0'),
('Guest471', NULL, 0, 135, 'bypKerJ1V729V17TAdAAE8l2E8YGroEbeNY', 'G', NULL, '0'),
('Guest546', NULL, 0, 136, 'mEUWOfPaKlTz8HSyKt0QO8pj2er5iiCgejA', 'G', NULL, '0'),
('Guest410', NULL, 0, 137, 'bMveJCJRnzJi58HCc1_1uovie5CBawgdATj', 'G', NULL, '0'),
('Guest531', NULL, 0, 138, '9hWIKRexjarHKHP4OaG3J2CmkQLqsxxduoh', 'G', NULL, '0'),
('Guest766', NULL, 0, 139, '56slzhFVrZDPm1aFp-aHNcnsXdyb9aWo3tA', 'G', NULL, '0'),
('Guest25', NULL, 0, 140, 'MRm4P7-RHzIKj3mT1oYeAO7c4OvtkDB2IaA', 'G', NULL, '0'),
('Guest416', NULL, 0, 141, 'Idovx5smfFkkcoxBGAFGUTAcAotULXf-nvE', 'G', NULL, '0'),
('Guest802', NULL, 0, 142, 'OZhbRewB1MXOwpcrYOh7Y6DLlvZUBD7B_f-', 'G', NULL, '0'),
('Guest182', NULL, 0, 143, 'G7hPz9rj4pHrFo8Thdo6ruMii0twMELGp8n', 'G', NULL, '0'),
('Guest819', NULL, 0, 144, '7DiHy8DVBgT6rnzw215DfqogOCuSZVUeVTq', 'G', NULL, '0'),
('Guest786', NULL, 0, 145, 'v9Qo3LKlvGsra6ypOUZ-y2lG-pooeSt52fd', 'G', NULL, '0'),
('Guest472', NULL, 0, 146, 'U2owzSCSwa0WEFv3nFguim77HhNm7iZZwTU', 'G', NULL, '0'),
('Guest386', NULL, 0, 147, 'fHP9F6YeQNTR8aiujZwqZLkriS59Wb4Oyw_', 'G', NULL, '0'),
('Guest441', NULL, 0, 148, 'OSxjkJikf5uWdpn-nufUOxuj3awJPAv5Mr6', 'G', NULL, '0'),
('Guest202', NULL, 0, 149, 'iz7ASMsetytxjlZGCvTpRLsjEgE8xTOntMu', 'G', NULL, '0'),
('Guest864', NULL, 0, 150, '_B3gyPfJoqSAWDwTTOea-sfkcn3VlgCygTr', 'G', NULL, '0'),
('Guest842', NULL, 0, 151, 'RrSLqyr4NtezyJOJt4IkoTpf75sxNYIa-o_', 'G', NULL, '0'),
('Guest938', NULL, 0, 152, '8j87STP6TDcc1HQGEBCYg7TN0x64S8BS-D8', 'G', NULL, '0'),
('Guest703', NULL, 0, 153, '7rujtFXF9vBr-IWyOfUcdbjzwVfwY6_I0NX', 'G', NULL, '0'),
('Guest147', NULL, 0, 154, '92DfgMm7ZA0-bmbirYW3fF2z6s_ra0LYAVm', 'G', NULL, '0'),
('Guest762', NULL, 0, 155, '2cRB7cbMYGmXEO__34boFKXjDYWqH4cvLR9', 'G', NULL, '0'),
('Guest347', NULL, 0, 156, 'HGnPDBahlOGAe1h-0uUiuSW4iYI8XlkGBhr', 'G', NULL, '0'),
('Guest32', NULL, 0, 157, 'ACyKZ84PdzVVsfoyBd0IrZ6LOGT3WG-HXnh', 'G', NULL, '0'),
('Guest257', NULL, 0, 158, 'TLI9sXYxvha_PCXUDzErhMtHP13g-0xjFZa', 'G', NULL, '0'),
('Guest789', NULL, 0, 159, 'HHnL3XPDEtc8JPDo-hKgg9zxpEWiq6EYo9q', 'G', NULL, '0'),
('Guest421', NULL, 0, 160, 'a4BX2vh3NhJI782MN03FN7QvmywAiI-YGuu', 'G', NULL, '0'),
('Guest250', NULL, 0, 161, 'CU3xI3Sag2aZIoYGVyHeoBvLrYOCXoiTIuF', 'G', NULL, '0'),
('Guest788', NULL, 0, 162, 'jbsDeY4acF0GxgM2XGbkdV8FCh8GPsIKPMm', 'G', NULL, '0'),
('Guest778', NULL, 0, 163, 'hsA6P0fL3vJcpSP0vU2GhKsnqWGCf6yLwga', 'G', NULL, '0'),
('Guest564', NULL, 0, 164, '4YTywiVGPtedWoEg4qgvuwBj9BSjZzKN7YZ', 'G', NULL, '0'),
('Guest430', NULL, 0, 165, 'EWODzGuEybFsh-6-aKk0PrVI55S4v1DJpWe', 'G', NULL, '0'),
('Guest668', NULL, 0, 166, 'WjOJJ-1vgiU9BUMajvCy0t0TtLNeyOXXrP6', 'G', NULL, '0'),
('Guest819', NULL, 0, 167, 'f71wAMAdCVO98zByFym0CuGx1YQRk0yxk5r', 'G', NULL, '0'),
('Guest630', NULL, 0, 168, 'NB6fmet2F5eKGPxglbFcewMduAjVTfk2rPO', 'G', NULL, '0'),
('Guest162', NULL, 0, 169, 'RggSmijJRWP7Ih2L4WstHCxJnHCjbNMHnh-', 'G', NULL, '0'),
('Guest563', NULL, 0, 170, 'OuHvum2LqN36GD6o1VNlbiu_oTCBgXd8WDz', 'G', NULL, '0'),
('Guest851', NULL, 0, 171, 'i1CDjzv1bZEw6-17oITvC6V5W1IWaxjTAoq', 'G', NULL, '0'),
('Guest540', NULL, 0, 172, 'twrXWwoMhESE-rx5qCMCPfkckV8L0mTIvMh', 'G', NULL, '0'),
('Guest119', NULL, 0, 173, 'zQbaolV0_9kX_mUshGZnqZmi_PNy8T8Dfw1', 'G', NULL, '0'),
('Guest999', NULL, 0, 174, 'HjKGa18Ytcd3PShaRLMpNhObKuMY8tYy21U', 'G', NULL, '0'),
('Guest299', NULL, 0, 175, 'T9y6GK3uSHIk7USp_QyG1uqu0HjL8j2NmRW', 'G', NULL, '0'),
('Guest957', NULL, 0, 176, 'Fg8rvCdT0NLPnq_RdpmbYq3bp_PKFnRlgxJ', 'G', NULL, '0'),
('Guest834', NULL, 0, 177, 'jrJtsSWvTU0sy5qpRXLPH2Wm5gRhHzqZezH', 'G', NULL, '0'),
('Guest379', NULL, 0, 178, '4sa18y5UYoZswkl-Hv8WoP7ESLwU6fvYMoY', 'G', NULL, '0'),
('Guest112', NULL, 0, 179, 'Qqa_dsONmtKGw26R99ZvVoGqGeErnHMs48s', 'G', NULL, '0'),
('Guest75', NULL, 0, 180, 'J555SDZQKaUcFvo6ChUGiplG0UT9HbZBPBg', 'G', NULL, '0'),
('Guest786', NULL, 0, 181, 'yIfDxpBwvY39bz_5HTz7F_L9d-9GA7JpE0a', 'G', NULL, '0'),
('Guest787', NULL, 0, 182, 'HorGSivH4ylrJRSCptV20KCbP4W6yL0akqX', 'G', NULL, '0'),
('Guest568', NULL, 0, 183, 'zCFC24erXpKPFwCj4fk_38Jmfsovx3OAT39', 'G', NULL, '0'),
('Guest412', NULL, 0, 184, 'H2-pnU0repaU2rTzwv9a3c4TG3j4fgOF22_', 'G', NULL, '0'),
('Guest504', NULL, 0, 185, 'p7hWGJ0yfN9m6W5qeF6_E8bpkF2GkKQK6uV', 'G', NULL, '0'),
('Guest544', NULL, 0, 186, 'MQawJt20Yi2Apz2Dxd1IV6XgNQcUKCpC3KI', 'G', NULL, '0'),
('Guest125', NULL, 0, 187, '6ySElGVI0ZjNqXiurIWrHiJtSJBSbcPQA2N', 'G', NULL, '0'),
('Guest675', NULL, 0, 188, '561QtRWGmJZT7C1NqN0-OufMo8gKY4y6wFy', 'G', NULL, '0'),
('Guest937', NULL, 0, 189, '_C2zoD3gwxTRT7drhK-uxNsfYwLNy9-pntW', 'G', NULL, '0'),
('Guest265', NULL, 0, 190, 'zC12Ygze0Dygk7ZoLXKw6pm1i16NT-TwtPM', 'G', NULL, '0'),
('Guest138', NULL, 0, 191, 's8cvcr9MYry6nNqS0JWgm3GwdsxWVD6LgbF', 'G', NULL, '0'),
('Guest83', NULL, 0, 192, '0_0RP_GTFxOVDRNubq63ZmPX6LbIWCr9dwP', 'G', NULL, '0'),
('Guest281', NULL, 0, 193, 'iohGaEFJf1h4JYOnVmNAgJn7eF9I5w9XXtR', 'G', NULL, '0'),
('Guest752', NULL, 0, 194, 'yYi-j_BQgaPfG0J2Io0-idCgdN9WuqeEo-V', 'G', NULL, '0'),
('Guest720', NULL, 0, 195, 'Ps_kds9GWnIts_AkcIjtntYpBJ1O3_TPphl', 'G', NULL, '0'),
('Guest522', NULL, 0, 196, 'I2Xv-tsJzaI3cxOPA5Fx3S73gLP25S9uxOM', 'G', NULL, '0'),
('Guest287', NULL, 0, 197, 'oT0lBI8lyZXOoS8AgvpCNubY2W_a-FfGj4-', 'G', NULL, '0'),
('Guest675', NULL, 0, 198, '7tNAIoIW-Hc5r1Yql2Rcj1UC9rJ-G3ZAZ23', 'G', NULL, '0'),
('Guest730', NULL, 0, 199, '2dNYHBvcHpLNXNXqmFYc5T0eAY-IAtxqnsT', 'G', NULL, '0'),
('Guest509', NULL, 0, 200, 'oZURsGW2Y65CDBfLc4STP3y_sb8JNoHNkiG', 'G', NULL, '0'),
('Guest858', NULL, 0, 201, 'yrEljFK3GRISJ-SWX22qsqlBpLOfEBEBuEH', 'G', NULL, '0'),
('Guest3', NULL, 0, 202, 'D-6miTdRMtpKV8LHUgFx72bDZU857V0SL1q', 'G', NULL, '0'),
('Guest248', NULL, 0, 203, 'l8m2cQ_4FBQQdzc6Rb0pH05L93LhH-bmavx', 'G', NULL, '0'),
('Guest113', NULL, 0, 204, 'CpIUxzX7hSvUY4GWIyTtu5fg-4tXb5G1mVA', 'G', NULL, '0'),
('Guest126', NULL, 0, 205, 'UcsnQaumbOh_EYJD_n4CinNhztzlc-1c303', 'G', NULL, '0'),
('Guest46', NULL, 0, 206, 'HbcZF9LRhLvu8pqHZxdPeNGGsRTyXBWH5Xk', 'G', NULL, '0'),
('Guest362', NULL, 0, 207, 'oJ0Q9ZX_WJB_EPwTZMs-pOyqJ4h5laqfbTQ', 'G', NULL, '0'),
('Guest863', NULL, 0, 208, 'EmBj2OWC3npL79_1iIU5Opl7NFBSqIf0VpO', 'G', NULL, '0'),
('Guest700', NULL, 0, 209, 'eBw2O-XaBP_Vxvlhp-9jVqw8T4BP-cj3jq3', 'G', NULL, '0'),
('Guest251', NULL, 0, 210, 'qOwRIF4IuqokO4UUMSmmnWkGZUiYOFoU1Hg', 'G', NULL, '0'),
('Guest647', NULL, 0, 211, '37A2yboLhpMQqokhNmgVQz6ZgQ2S1mY70Dp', 'G', NULL, '0'),
('Guest783', NULL, 0, 212, '0GgzZH7lDWVeEZiZ8WSkkkx-oJeesvTiY-R', 'G', NULL, '0'),
('Guest902', NULL, 0, 213, 'oSf9Hdqfr_eT2LZ96GHJ9X4P663tooN3DyT', 'G', NULL, '0'),
('Guest597', NULL, 0, 214, 'y40cnxc8jubpKXJhWYCroZH3voH0CyY_RxZ', 'G', NULL, '0'),
('Guest952', NULL, 0, 215, '3rV-iG97GMRshvtLLRAIpgRf389XkHQztas', 'G', NULL, '0'),
('Guest692', NULL, 0, 216, 'EG1fR2dWPn8I6stcXLeGbx1mcrPrb-QQDj3', 'G', NULL, '0'),
('Guest157', NULL, 0, 217, 'Oz5yd9vkfmWzniVGkeesk4iDg87zIYckGx7', 'G', NULL, '0'),
('Guest259', NULL, 0, 218, 'hAXh_pXfO2AFsnc0TthswI-yPP9ADxNYm2Y', 'G', NULL, '0'),
('Guest773', NULL, 0, 219, 'cS9goY6bCKVDDDEhuyZfMLgPJ7Y2pbb4s0Q', 'G', NULL, '0'),
('Guest132', NULL, 0, 220, 'QznV3mSWssp2DV2fFtWNKtHz-q0OvGA6wLJ', 'G', NULL, '0'),
('Guest543', NULL, 0, 221, 'f1FmCKgJjLvsXN9VOJGdrTL_ONDr2sNlEE0', 'G', NULL, '0'),
('Guest156', NULL, 0, 222, 'OZxIyeh3ichbULVTrIr_lnXzAnIbNXr_msK', 'G', NULL, '0'),
('Guest854', NULL, 0, 223, 'S0yBlVQ2SAjOxaN4xGHHa3kiOLqd6lPABHf', 'G', NULL, '0'),
('Guest958', NULL, 0, 224, 'TVfxjD91Bc7SnTqJCYkq54J1B5dW_u2VhY6', 'G', NULL, '0'),
('Guest42', NULL, 0, 225, 'iWKv12f7puNa2cEfHzHQoYGga-4kriSBnOv', 'G', NULL, '0'),
('Guest665', NULL, 0, 226, '2IHa1nJLRnpHwfeYhz_joLTX95Oe2nd7w9G', 'G', NULL, '0'),
('Guest271', NULL, 0, 227, 'Xa9tS86eXUjy6sJm9ViQeO-D6AheLCc99S_', 'G', NULL, '0'),
('Guest552', NULL, 0, 228, 'QRoTpf8dGXJgK7Y33HROTuLF2HckTBfSvXw', 'G', NULL, '0'),
('Guest295', NULL, 0, 229, '2BpsclIowRg1L_b-8VL0dipDIgJlr_qTfvv', 'G', NULL, '0'),
('Guest638', NULL, 0, 230, 'MecvnTbmtprB_UuzhDbUOy2S7Ggv_86cP5u', 'G', NULL, '0'),
('Guest966', NULL, 0, 231, 'fhfyzXD3W4uQEnVuxLD1mYyfBFflNMUA8oz', 'G', NULL, '0'),
('Guest734', NULL, 0, 232, 'AB6dYuc_0hk74NwxVamLxlPEJyme0c-xgqt', 'G', NULL, '0'),
('Guest921', NULL, 0, 233, 'Cg1llyev3eo_hr8Foem1mYeEvZ-TtaSYK-0', 'G', NULL, '0'),
('Guest241', NULL, 0, 234, 'EIcsTgUO-5zHtTd19ueQI2KvCdlBN_Z8W0G', 'G', NULL, '0'),
('Guest253', NULL, 0, 235, 'Cgf59YsWlqe8J9ffsUuANC-tUHkF6FgL7bB', 'G', NULL, '0'),
('Guest585', NULL, 0, 236, 'Dc6yU_tycRHOK-7YaRNyPOEKf6ji0mZi95T', 'G', NULL, '0'),
('Guest899', NULL, 0, 237, 'j7kquh3n6Y6GugzIeta97vVNtiXWJLcegJH', 'G', NULL, '0'),
('Guest806', NULL, 0, 238, 'nzkc-7s2k0IfjB22nWNBMinxvXomZP57AyI', 'G', NULL, '0'),
('Guest84', NULL, 0, 239, 'IgFVeZneOAdmR5mgIHIXI9w9HOkTcbBF9OB', 'G', NULL, '0'),
('Guest497', NULL, 0, 240, '_1tBGKI1urFYoHIDpmt_843XsSF71ay7Eun', 'G', NULL, '0'),
('Guest956', NULL, 0, 241, '5gxCEXCNF8hxZsyOE8hnfjeWbNxTOkVpIpB', 'G', NULL, '0'),
('Guest828', NULL, 0, 242, '68XddAYKRDJwy1kRdYW632gcc-sGOKj8pbd', 'G', NULL, '0'),
('Guest690', NULL, 0, 243, 'av95uKl0vYybFf2UMPbtC-MEhHS1BrVxvR9', 'G', NULL, '0'),
('Guest722', NULL, 0, 244, 'VHvIGfWy7lawIm0s0NLnuxdJPpWYbuZ16zD', 'G', NULL, '0'),
('Guest370', NULL, 0, 245, 'mVnVSHezbeScOhrUDx370p850pJVVKlyNAn', 'G', NULL, '0'),
('Guest67', NULL, 0, 246, 'EIZ4yex0inK--7EF_7AoF4B0PL3ZY9grYKd', 'G', NULL, '0'),
('Guest482', NULL, 0, 247, 'u5b5tXnZNeKUcvv4cNk1fL9NTf7hUihkoKg', 'G', NULL, '0'),
('Guest774', NULL, 0, 248, 'TjTPa8HO9C2oL9cIwVmh322yAEZcZBH-PFw', 'G', NULL, '0'),
('Guest10', NULL, 0, 249, '-YFDatezQUY9_0weDUVMUAzUKaC-UvL5lMV', 'G', NULL, '0'),
('Guest397', NULL, 0, 250, 'Ugux41tNMO0N_zGoOL4lvMRABzPY3Tv6io_', 'G', NULL, '0'),
('Guest191', NULL, 0, 251, '2PoUpWA6IyJpquVZHc3iTyCZu5ihWwSHXxf', 'G', NULL, '0'),
('Guest855', NULL, 0, 252, 'hWSo2WOO-KRKNkMe5MlR_sX0tmJQqiXrJYm', 'G', NULL, '0'),
('Guest571', NULL, 0, 253, 'c01eiBw_IBDI-ulTwTPnhGoVsrpDhOnxpAl', 'G', NULL, '0'),
('Guest12', NULL, 0, 254, 'KAC1qcDdfyvdoWGTrynqA-2m6oKtw0gyyfM', 'G', NULL, '0'),
('Guest536', NULL, 0, 255, 'Wm_AWxri899SMqZSG2llPdGIhq9s4pWqU4f', 'G', NULL, '0'),
('Guest112', NULL, 0, 256, 'LU0lv4RotxNLH2TIoNt-vdem9kE8FQU6kkM', 'G', NULL, '0'),
('Guest799', NULL, 0, 257, 'Pu0w1xbfiRho79TXUijE0r1ofynO7CnN35B', 'G', NULL, '0'),
('Guest460', NULL, 0, 258, 'FCPsqp3ErmLy2QPvo1t4WVGqsdGErxrcH65', 'G', NULL, '0'),
('Guest38', NULL, 0, 259, 'zo0MkVwofEyB0v8DGxiWKj9fxpYvoSxJo6O', 'G', NULL, '0'),
('Guest792', NULL, 0, 260, 'zZR3lAW5rRtiGz7Iw0Pz9dzMxnVS9wvxsBE', 'G', NULL, '0'),
('Guest334', NULL, 0, 261, 'UAApq0dfTFX9DFjBmiYA7RclvW-hepfP4xo', 'G', NULL, '0'),
('Guest725', NULL, 0, 262, '5l7arm-fseTCZYnGOdAUBCMgsUTihosGyL-', 'G', NULL, '0'),
('Guest149', NULL, 0, 263, '3LhoQvbHhJBYARGEchqmnCrPmu5_4Dtrm9n', 'G', NULL, '0'),
('Guest104', NULL, 0, 264, 'yqM5n6sEMNkpwkMInO9amIrddBunjIQVEiG', 'G', NULL, '0'),
('Guest813', NULL, 0, 265, '4_EfGmHZmZ3XG5jw3NJLaoyv0nm8u9PSCVk', 'G', NULL, '0'),
('Guest785', NULL, 0, 266, 'tNVLrr1tAFGSG-kdlb8RIf-uN1nhikW2HLV', 'G', NULL, '0'),
('Guest101', NULL, 0, 267, 'OKgh7y_nVy8Ht_Wdh8mHlWeQ3j72zjmtIzz', 'G', NULL, '0'),
('Guest913', NULL, 0, 268, '39cW2PHzJiJ0nNNZLamOKNES5bOiCs-gCqk', 'G', NULL, '0'),
('Guest637', NULL, 0, 269, 'sDr8FQVnN0t-KvatSLZl70g25kmTdNgAeLe', 'G', NULL, '0'),
('Guest470', NULL, 0, 270, 'vheVfCmhMnbTVMhT0pnRHveOTtwl8gJG4g0', 'G', NULL, '0'),
('Guest378', NULL, 0, 271, 'NIIs_YxFMyPPHDouMEhmZ17CZbi3zGkKJkV', 'G', NULL, '0'),
('Guest582', NULL, 0, 272, '1KMlHsJ01xSTVJlETmAs1p5XU9Nw-6cy9Sy', 'G', NULL, '0'),
('Guest522', NULL, 0, 273, 'xhjCuikF3COiwxdeV7cxYNxVUlc13VphZdJ', 'G', NULL, '0'),
('Guest896', NULL, 0, 274, 'XJwxYXB4ArFrKWnGtLLHRAyVm17d-DyPe8r', 'G', NULL, '0'),
('Guest394', NULL, 0, 275, 'a2khc2ccu85QeVhKnk7DgC2kKevZdLvAgr6', 'G', NULL, '0'),
('Guest975', NULL, 0, 276, 'wL5Q59FocoxGD4_sqaM0scLPA8eGPEBUnqT', 'G', NULL, '0'),
('Guest137', NULL, 0, 277, 'v_QuIi7PFuSroFWfn6TRZESISNO4wwHgJMB', 'G', NULL, '0'),
('Guest932', NULL, 0, 278, 'BGZ18DW01RUqcAI3BsrTEeqapkeDaz66X5x', 'G', NULL, '0'),
('Guest70', NULL, 0, 279, 'y-NvNngKz35KTuBl_m_RcI2mQ6VWqM5MOFj', 'G', NULL, '0'),
('Guest30', NULL, 0, 280, 'bNlvXHBRl4nAoicmDojB35eO4EzRqdZvdta', 'G', NULL, '0'),
('Guest512', NULL, 0, 281, '4KIMbf8XOkSC5BLrglBndDcX6XDPDDdzxW4', 'G', NULL, '0'),
('Guest529', NULL, 0, 282, 'Z2XqDa3hpnyhq4FMr5kW3cf7K6g-IaXWUyZ', 'G', NULL, '0'),
('Guest877', NULL, 0, 283, 'Wg0vKSKZO44IjvVFigK6emSoL6L6dcJFeik', 'G', NULL, '0'),
('Guest665', NULL, 0, 284, 'zQQX4Llya8b_HxP_p-1rEmHK2ML0NDq_uIh', 'G', NULL, '0'),
('Guest352', NULL, 0, 285, 'P2Is5TVntWE8H-c5DCsCso4tzhH8w82AU1o', 'G', NULL, '0'),
('Guest139', NULL, 0, 286, 'b2TIUewJml827E3tmjMwx6N_zaW7l2kHvEz', 'G', NULL, '0'),
('Guest585', NULL, 0, 287, 'KfuA_bNQ-65pOmGtGoC_Dp78NPe5iug-su2', 'G', NULL, '0'),
('Guest303', NULL, 0, 288, '4IuaznhUaQ8fYBiKW_DB_d1PW6edujalsBq', 'G', NULL, '0'),
('Guest9', NULL, 0, 289, 'RhffPJ8vrORx6AY8BQlVbSczvnVzaW1wY5F', 'G', NULL, '0'),
('Guest442', NULL, 0, 290, 'Gx5Tw-GfRRmckXX2oBAy5ge-XlIAZoefczH', 'G', NULL, '0'),
('Guest308', NULL, 0, 291, 'm6Qo6f4J5vrpK2Fj-RjtIQxpw5khxAP1djM', 'G', NULL, '0'),
('Guest910', NULL, 0, 292, 'warQzoQTFccrwbgDb7mVEvs42-SNSiwIT1g', 'G', NULL, '0'),
('Guest425', NULL, 0, 293, 'E4Mp-OTiDPL8NhSB7Y5xXyyIxDAK8AVfWHb', 'G', NULL, '0'),
('Guest910', NULL, 0, 294, 'AGzVn3IbzvKdMhfjBtCcKbj9iYBjVfIb4Ni', 'G', NULL, '0'),
('Guest955', NULL, 0, 295, '6tTo5zCPFCbB1pwVOnXv8dEcFEJaUV14x2Z', 'G', NULL, '0'),
('Guest272', NULL, 0, 296, 'a0G390QvPC68d7Xc22wisyXFxcruGTmE8RS', 'G', NULL, '0'),
('Guest857', NULL, 0, 297, 'ct0oG4HsKNgU0dUAmJ1nNRzYzYA00uH-UTy', 'G', NULL, '0'),
('Guest597', NULL, 0, 298, '2KBbyR9ELZldjp7whoJLbnYjMVgEeXEpef0', 'G', NULL, '0'),
('Guest868', NULL, 0, 299, 'Dr4_DIXfo420JFsQFnT00V38KJwbHrzJ4bK', 'G', NULL, '0'),
('Guest958', NULL, 0, 300, 'ORnrf_E9Fgj1LE8Xbegzrk4KVO6stIerJKh', 'G', NULL, '0'),
('Guest430', NULL, 0, 301, 'XkUplBAH5HEm1rWHvrRd2aQCh9AQ5-8prbK', 'G', NULL, '0'),
('Guest791', NULL, 0, 302, 'aEgVvxmr1FnoMpPCbI04JE6NbjNCZlAHL_b', 'G', NULL, '0'),
('Guest884', NULL, 0, 303, 'P5W-hL9HEG7ByQ0FQnGR7E_nLREWXl0kvdD', 'G', NULL, '0'),
('Guest159', NULL, 0, 304, 'dgDPOdymNXeNAseX3Cbhqprg6wx9t1XvesZ', 'G', NULL, '0'),
('Guest562', NULL, 0, 305, 'LCISmCz93yUW6nDW8s0OUEY7dJCws6lqdRg', 'G', NULL, '0'),
('Guest624', NULL, 0, 306, 'Wfh2gT-_12WlhbrgXC1zjqOrOZQUIyOcC6P', 'G', NULL, '0'),
('Guest773', NULL, 0, 307, '1aIVc9X_iE3TeTa2tbhePIXA5_Q63WiCSCu', 'G', NULL, '0'),
('Guest670', NULL, 0, 308, 'c_MFPLtPV8LwX0PgWoHw9aeJffBvq_7Lsna', 'G', NULL, '0'),
('Guest628', NULL, 0, 309, '347aio6tcZCceHAv6Mt8w66T_HcATiah0-X', 'G', NULL, '0'),
('Guest731', NULL, 0, 310, 'efXAbmBZB5F5rnp9SB4QS4mustcshhTN25L', 'G', NULL, '0'),
('Guest757', NULL, 0, 311, 'ZbN4ke64LVOakezqO_HKYcB0zxelkQPygsr', 'G', NULL, '0'),
('Guest965', NULL, 0, 312, 'mMBO8WBkXCAoMxJXjN5mNgY_02G_EGRPt9c', 'G', NULL, '0'),
('Guest123', NULL, 0, 313, 'z9pSJiYM4dmiy9VhnLOrMRuJwKthbTUoeU3', 'G', NULL, '0'),
('Guest912', NULL, 0, 314, 'GAPNnXIO8ZZGO7M6JpHA-ZXAqxUGLcxjB7t', 'G', NULL, '0'),
('Guest190', NULL, 0, 315, 'F3JK5-d5irhixO80rvWFuUOURigbdTmhEkB', 'G', NULL, '0'),
('Guest341', NULL, 0, 316, '4broT3vI7kWJzspLzJlmoSnJwMYIP2M2kWt', 'G', NULL, '0'),
('Guest635', NULL, 0, 317, 'Odpv5onP-5-7sZxtjngdrzYSUTW_drU8Sb2', 'G', NULL, '0'),
('Guest858', NULL, 0, 318, 'Y6vEPi2Rf0QtmbTxLbM-14RxF7FMDdm7aV6', 'G', NULL, '0'),
('Guest261', NULL, 0, 319, 'PFZ9iwRcsUb0x7cLPnEATWoonxZU8ArArS5', 'G', NULL, '0'),
('Guest395', NULL, 0, 320, 'osKbg6hH0VtCztxdOli1V0-M5Z_DV8rYNAR', 'G', NULL, '0'),
('Guest986', NULL, 0, 321, 'zYpZ4qwuc4m7xw2cAykmQh5Qb2CYO7pUFf-', 'G', NULL, '0'),
('Guest697', NULL, 0, 322, 'kQS_lytJIq6yBr6s3hnx966yoY-yIj39-R8', 'G', NULL, '0'),
('Guest799', NULL, 0, 323, 'V0FUTXua5337ilVAVkMXh4UcNffUu35uNpV', 'G', NULL, '0'),
('Guest707', NULL, 0, 324, '_OKVryTUGLP98sn_fKD3Jb-xd0SgEfPSsXY', 'G', NULL, '0'),
('Guest164', NULL, 0, 325, 'IDfh9OHFNcHEhOSm_UwIrwSqZ2Beypdoot8', 'G', NULL, '0'),
('Guest950', NULL, 0, 326, 'ik52eJmy6K5bsis0sotQ35SdxLjTIbfSv80', 'G', NULL, '0'),
('Guest249', NULL, 0, 327, '85MclaNZCqSwq1VVQvLOs7jOF71CmGQL41-', 'G', NULL, '0'),
('Guest514', NULL, 0, 328, 'nfbtYyV4HwraBT3I9B-OxFFPHPc7yDG2U3b', 'G', NULL, '0'),
('Guest198', NULL, 0, 329, 'yotd2LSEObMuF69-KrvP-mFFQC33uRXXX7e', 'G', NULL, '0'),
('Guest36', NULL, 0, 330, 'R45F8ld9KKfsOzLU2vXjx4HHR1xA-KsR-zA', 'G', NULL, '0'),
('Guest585', NULL, 0, 331, '5MX5AwMEvGKh_494-L37f6EIPIjDb6F_zs2', 'G', NULL, '0'),
('Guest11', NULL, 0, 332, 'ozJeZ3GfP8zuwtJ8mXwkCZLZjbfSYLK2KYG', 'G', NULL, '0'),
('Guest694', NULL, 0, 333, 'iCErlA1cC3Zw4nN_N955srNDhbpwDx_CpKT', 'G', NULL, '0'),
('Guest375', NULL, 0, 334, 'y_REkV7eREMCGiZ51Kl3APNbR48_SGgEMJC', 'G', NULL, '0'),
('Guest25', NULL, 0, 335, 'DfRSB7p9fX_7-UGOnXVCK7AY_TOyE_sn1Uh', 'G', NULL, '0'),
('Guest592', NULL, 0, 336, '7auOUbCQs8k93_L9yT8I2khvJIE-5Emnal6', 'G', NULL, '0'),
('Guest910', NULL, 0, 337, 'kEqneDIEiidIyjhzWHsEMqpOh7EWzQblHjZ', 'G', NULL, '0'),
('Guest899', NULL, 0, 338, 'hQ3SaizMo6-grmOdpjuKRXrP7L6ykNUzHtb', 'G', NULL, '0'),
('Guest764', NULL, 0, 339, 'PfYVu4lEOwBwgu3O-FOyN2wr43asEbt9Dzh', 'G', NULL, '0'),
('Guest47', NULL, 0, 340, 'caDTowGRy2TZArl4FlW7BhtsZ7HIXGa5zTT', 'G', NULL, '0'),
('Guest211', NULL, 0, 341, 'jXqDIo9YiK16LL4OGi7a9b1edWMhanfqnZV', 'G', NULL, '0'),
('Guest893', NULL, 0, 342, '7Un-0A9uHtAGW3G82IoYZHgeRRghxJ3yZRg', 'G', NULL, '0'),
('Guest431', NULL, 0, 343, 'yXNjtd69IjyXSB_Gt3hYHjneRQM1Ku0d1kn', 'G', NULL, '0'),
('Guest896', NULL, 0, 344, 'Uh4DP06Uxkv-150NvcYHfJYZNWnRLR-O-fB', 'G', NULL, '0'),
('Guest86', NULL, 0, 345, 'F9z35L8FkDmyzl_L8S4UaGaZDtXFMf6IXyR', 'G', NULL, '0'),
('Guest140', NULL, 0, 346, 'eKWh26dekJC9viN0ztTL6pFhfjSbsMSTN-m', 'G', NULL, '0'),
('Guest409', NULL, 0, 347, 'lri3m1pmjPGzSL9d37g2UdsJJbKvuaZtJMF', 'G', NULL, '0'),
('Guest905', NULL, 0, 348, 'AsaU5xAZL4jcPgk7P8BsAL-Tg7EUdsI5QDr', 'G', NULL, '0'),
('Guest557', NULL, 0, 349, 'tXv35SFcgi2pIkGPA6_1fUMb3HmlW0ZjmSt', 'G', NULL, '0'),
('Guest657', NULL, 0, 350, '1RTziYC9qJH26jnnR-sssWrSVePQ8Lc9w_1', 'G', NULL, '0'),
('Guest54', NULL, 0, 351, 'LlrSGG72o23vRtelV3Y7DK2wycqHoiHSwop', 'G', NULL, '0'),
('Guest852', NULL, 0, 352, 'rLfZxySstKTmUiDwrLgdafY8YrXMywYq0TQ', 'G', NULL, '0'),
('Guest617', NULL, 0, 353, 'BdBlBcLGd0lZNhge1K475P5qAP7AScghkhV', 'G', NULL, '0'),
('Guest905', NULL, 0, 354, 'CfvhQK4ocGY8U7wEGVqgXF3TKygYBawG4jc', 'G', NULL, '0'),
('Guest258', NULL, 0, 355, 'GPlsoA9P36_81rsf3zqcC24Ky3gmUg5GXc7', 'G', NULL, '0'),
('Guest999', NULL, 0, 356, 'Dto1r0GxevkBNeEgFH2gYsWqKHDukzg_l7N', 'G', NULL, '0'),
('Guest595', NULL, 0, 357, '5jBejHYJzrB9BXve_mpjvrPSxCClMM91psq', 'G', NULL, '0'),
('Guest78', NULL, 0, 358, 'qiUnHYNAk5kltR4YZTfSiGNUPXipJHgxL-4', 'G', NULL, '0'),
('Guest851', NULL, 0, 359, 'v3AR6PD9zLhRM0MGsHAOOn1CauUS9yqyLnu', 'G', NULL, '0'),
('Guest536', NULL, 0, 360, 'rXUgYvBDHqErx786kt8L8B3WuTqeimAYY4P', 'G', NULL, '0'),
('Guest83', NULL, 0, 361, 'PR1sTg7Udfm5VvANnOv36obQ7pzB2IMNZav', 'G', NULL, '0'),
('Guest233', NULL, 0, 362, '8nWvdRtiUkUGHG6fBwgfEWJ5zPvxqAtxpJP', 'G', NULL, '0'),
('Guest883', NULL, 0, 363, 'fkW8dk8uxGisdvxIig0IoJLmBuMr-bQG0u9', 'G', NULL, '0'),
('Guest526', NULL, 0, 364, '1hka-wP0wQk8echy4ox3xV3G1x0_dTheATs', 'G', NULL, '0'),
('Guest426', NULL, 0, 365, 'wtvL1s5QwcmBW4ownRKHZUlnFPdetjW5xrN', 'G', NULL, '0'),
('Guest484', NULL, 0, 366, 'tYsrxrv5rFJ2SoLmj0l5qzE2W0DvonaozDv', 'G', NULL, '0'),
('Guest81', NULL, 0, 367, 'JF0FXNND0MbtM1Sc2DqUaIJTEB0jrHFtTOz', 'G', NULL, '0'),
('Guest161', NULL, 0, 368, 'XYrY0HgznNpZRf5Vy0gLHLE0q5Q7vdQKNR_', 'G', NULL, '0'),
('Guest664', NULL, 0, 369, '7zKFFxls56EVm6FnJwPem6BeuLO_FZj3t6k', 'G', NULL, '0'),
('Guest560', NULL, 0, 370, '6YIFXie312Wh9lxIpqpjCChSMT64uAwXoZ-', 'G', NULL, '0'),
('Guest485', NULL, 0, 371, 'Db_ZmyOEbv_b8Glt6Vao3_VlJekLH9VgrQE', 'G', NULL, '0'),
('Guest800', NULL, 0, 372, 'EcnEFxn_M-XNYtnvnFVazZAq0gTwiPBGGjB', 'G', NULL, '0'),
('Guest300', NULL, 0, 373, 'Fb1k6poQpE-o-vlTp90pN2umvjM_CtLsVdE', 'G', NULL, '0'),
('Guest255', NULL, 0, 374, 'zfk-mhDszG5DLQZyXu81WIzxSVjpbrxQK7j', 'G', NULL, '0'),
('Guest491', NULL, 0, 375, 'rxJ77GIHHPVOta0UnLzQ5IbcLgyrPk22sl_', 'G', NULL, '0'),
('Guest787', NULL, 0, 376, '_rxtXxpVzCRR4cfQc3D-ES8MQum_L1uX2y4', 'G', NULL, '0'),
('Guest557', NULL, 0, 377, 'DkXCy77PTLmPjDlkTIXMwHiqEyhHjNLa_xk', 'G', NULL, '0'),
('Guest74', NULL, 0, 378, 'OQsOCRiHoZrapCze-7EQGBcSzcM6i4pc9bf', 'G', NULL, '0'),
('Guest293', NULL, 0, 379, 'gsvd_HDrrGZ7Y4p1oOzjSzwlDGd4DQWvvvt', 'G', NULL, '0'),
('Guest479', NULL, 0, 380, 'uQhLmd_NHYj3HOKQMEpf7CcyDv8fjG9kXP6', 'G', NULL, '0'),
('Guest467', NULL, 0, 381, 'k4SFQWe7kMTXQVxhkUhyOk9HKjK8WBxmtyK', 'G', NULL, '0'),
('Guest159', NULL, 0, 382, 'm1c5sKWw1qNdOoMSE9qXqywtm--1B73vHw0', 'G', NULL, '0'),
('Guest889', NULL, 0, 383, 'XiSrHTLPqoYMw3bkAnoU8M6IhoHZ_u-YciF', 'G', NULL, '0'),
('Guest15', NULL, 0, 384, 'DAbPvLlmhMTlSHI0SsezYpDxhH72STw1PTh', 'G', NULL, '0'),
('Guest945', NULL, 0, 385, 'RtTEknz-Gdh5Hzz9SyqupcS_7Gsm-1KCnaE', 'G', NULL, '0'),
('Guest391', NULL, 0, 386, '9eJSREpUM2gEHdniRFRKV_v9-yfdV_20n3L', 'G', NULL, '0'),
('Guest44', NULL, 0, 387, 'sGrZHW-cwB7fMRrHRmLRFEUqjGiwuIH9wkS', 'G', NULL, '0'),
('Guest756', NULL, 0, 388, 'slj1OWFNhULdih8_WuQ_-UXWwv-BGkiYFJr', 'G', NULL, '0'),
('Guest367', NULL, 0, 389, 'WsUVDPIdmV8O628jFAPXJPWLCkw4shSSAOW', 'G', NULL, '0'),
('Guest547', NULL, 0, 390, 'FnxcL7NP6H2T7C8LF85ZcZMQoPcIyz2evrN', 'G', NULL, '0'),
('Guest114', NULL, 0, 391, 'ldfD09urVc7xrZlKB3Cak-l5ZU6_C_Kqx4B', 'G', NULL, '0'),
('Guest192', NULL, 0, 392, 'lKgkdtmDZdGGMyUi-_RGS5PIb1JLFTiXxsN', 'G', NULL, '0'),
('Guest449', NULL, 0, 393, 'jbCP5dDT8x1LgrRA5-xgwmGEcmrLfZC59Z8', 'G', NULL, '0'),
('Guest335', NULL, 0, 394, '9UjPqwbVelIDhh45gy44zZeNvjSLGHLh0mb', 'G', NULL, '0'),
('Guest388', NULL, 0, 395, 'pjJgiqbW6NQZ0WV8rpJWzRH4kHdlpqivPkz', 'G', NULL, '0'),
('Guest373', NULL, 0, 396, 'j8DpVnZ-jyZ4VbfJqxRzX4Z7aNixa38QgJl', 'G', NULL, '0'),
('Guest831', NULL, 0, 397, 'tSGKxiY-kTVE3-gBMXHLNMsKEoz1yqV47sZ', 'G', NULL, '0'),
('Guest445', NULL, 0, 398, 'kOUM1cu-SUtruvz_D5ggOTchLVZ1cOK5ruF', 'G', NULL, '0'),
('Guest465', NULL, 0, 399, '4Om_9rkYTT7CdhLPnKehKQZhIrdTVy9daAS', 'G', NULL, '0'),
('Guest29', NULL, 0, 400, 'bylWLGfq4WfaVUlllBOE925W1EYtF787Kdd', 'G', NULL, '0'),
('Guest569', NULL, 0, 401, 'q3WZiW_bESfNz-smxJjtx4zF9ZpOSkWM6rW', 'G', NULL, '0'),
('Guest209', NULL, 0, 402, '73pkIa-a5FE6z1kdmrtqPDMEG_hE5AXPafa', 'G', NULL, '0'),
('Guest603', NULL, 0, 403, 'rm7jehvSqlhiRifDoPfLFhpuXEWWez5BJ6s', 'G', NULL, '0'),
('Guest118', NULL, 0, 404, 'uC3cjPWkA42W7MMQC9Nrw7VT5dWW4v8wXgg', 'G', NULL, '0'),
('Guest141', NULL, 0, 405, '-CX0BwiNQnYMymKtz-XQyxQO63KSTn08_Eh', 'G', NULL, '0'),
('Guest531', NULL, 0, 406, 'HSo9dK74Y1BL7HVpLdiCpEIJGtKliigZiOB', 'G', NULL, '0'),
('Guest790', NULL, 0, 407, 'yucPaZzralMs66LhTet10SFin2IEP7hLNC_', 'G', NULL, '0'),
('Guest280', NULL, 0, 408, 'Q5HSoKjDM-p3xJADsE8Z4UVtwBFzJvnkHYN', 'G', NULL, '0'),
('Guest412', NULL, 0, 409, 'vLd0_O_M6cL2gemCKTUMTPH5Djmwdv-fOg-', 'G', NULL, '0'),
('Guest603', NULL, 0, 410, 'Jw02FcTrc5iBJuYiHY2w-Dvdak3nPiIxPJQ', 'G', NULL, '0'),
('Guest847', NULL, 0, 411, 'K6pRlgs1r8ZrfuGfo-GVPxtqOQcsIKBL0ID', 'G', NULL, '0'),
('Guest923', NULL, 0, 412, 'iGYu0rV565iINidtguoE3VB-jM2kHgygIxV', 'G', NULL, '0'),
('Guest862', NULL, 0, 413, 'OUzsy0s-iRfx7CqFJg_Cl7XuBo5QyPxvUTZ', 'G', NULL, '0');

-- --------------------------------------------------------

--
-- Table structure for table `servers`
--

CREATE TABLE `servers` (
  `serverIP` varchar(25) NOT NULL,
  `matchID` int(11) DEFAULT NULL,
  `publicToken` char(30) DEFAULT NULL,
  `privateToken` char(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `servers`
--

INSERT INTO `servers` (`serverIP`, `matchID`, `publicToken`, `privateToken`) VALUES
('127.0.0.1:42402', NULL, 'RANDOMTOKEN', 'privatetoken42402'),
('127.0.0.1:42403', NULL, 'testtoken42403', 'privatetoken42403');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `matches`
--
ALTER TABLE `matches`
  ADD PRIMARY KEY (`matchID`);

--
-- Indexes for table `parties`
--
ALTER TABLE `parties`
  ADD PRIMARY KEY (`partyHostID`);

--
-- Indexes for table `players`
--
ALTER TABLE `players`
  ADD PRIMARY KEY (`uid`);

--
-- Indexes for table `servers`
--
ALTER TABLE `servers`
  ADD PRIMARY KEY (`serverIP`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `matches`
--
ALTER TABLE `matches`
  MODIFY `matchID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=233;

--
-- AUTO_INCREMENT for table `players`
--
ALTER TABLE `players`
  MODIFY `uid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=414;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
