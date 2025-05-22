-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 22, 2025 at 06:46 AM
-- Server version: 8.0.36
-- PHP Version: 8.2.18

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `paperclip_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `students_teacher1`
--

CREATE TABLE `students_teacher1` (
  `id` int NOT NULL,
  `lrn` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `times_exited` int DEFAULT '0',
  `screenshots_taken` int DEFAULT '0',
  `keyboard_used` int DEFAULT '0',
  `flagged_as_cheater` tinyint(1) DEFAULT '0',
  `exit_code` varchar(255) DEFAULT '',
  `CREATED_AT` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED_AT` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `students_teacher1`
--

INSERT INTO `students_teacher1` (`id`, `lrn`, `name`, `times_exited`, `screenshots_taken`, `keyboard_used`, `flagged_as_cheater`, `exit_code`, `CREATED_AT`, `UPDATED_AT`) VALUES
(1, 'S1001', 'John Doe', 0, 0, 0, 0, 'A1B2C3', '2025-05-21 09:57:34', '2025-05-22 03:46:26'),
(2, 'S1002', 'Jane Smith', 0, 0, 0, 0, 'D4E5F6', '2025-05-21 09:57:34', '2025-05-22 03:46:24'),
(3, 'S1003', 'Peter Jones', 0, 0, 0, 0, 'G7H8I9', '2025-05-21 09:57:34', '2025-05-22 03:46:22'),
(4, 'S1004', 'Emily White', 0, 0, 0, 0, 'J0K1L2', '2025-05-21 09:57:34', '2025-05-22 03:46:20');

-- --------------------------------------------------------

--
-- Table structure for table `students_teacher2`
--

CREATE TABLE `students_teacher2` (
  `id` int NOT NULL,
  `lrn` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `times_exited` int DEFAULT '0',
  `screenshots_taken` int DEFAULT '0',
  `keyboard_used` int DEFAULT '0',
  `flagged_as_cheater` tinyint(1) DEFAULT '0',
  `exit_code` varchar(255) DEFAULT '',
  `CREATED_AT` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED_AT` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `students_teacher2`
--

INSERT INTO `students_teacher2` (`id`, `lrn`, `name`, `times_exited`, `screenshots_taken`, `keyboard_used`, `flagged_as_cheater`, `exit_code`, `CREATED_AT`, `UPDATED_AT`) VALUES
(1, 'S2001', 'Michael Brown', 0, 0, 0, 0, '123456', '2025-05-21 09:57:34', '2025-05-21 10:50:20'),
(2, 'S2002', 'Sarah Davis', 0, 0, 0, 0, '123456', '2025-05-21 09:57:34', '2025-05-21 10:50:43'),
(3, 'S2003', 'David Wilson', 0, 0, 0, 0, 'S9T0U1', '2025-05-21 09:57:34', '2025-05-21 10:43:17'),
(4, 'S2004', 'Laura Miller', 0, 0, 0, 0, 'V2W3X4', '2025-05-21 09:57:34', '2025-05-21 10:43:17'),
(5, 'S2005', 'Chris Green', 0, 0, 0, 0, 'Y5Z6A7', '2025-05-21 09:57:34', '2025-05-21 10:43:17');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `identification` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` varchar(50) DEFAULT 'teacher',
  `CREATED_AT` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `identification`, `password`, `role`, `CREATED_AT`) VALUES
(1, 'teacher1', '$2y$10$Wc5nCNkeHOxOFS99B3mS8OSbYjqajM/M.0fuc5MZFajOZC8PayBO.', 'teacher', '2025-05-21 09:46:06'),
(2, 'teacher2', '$2y$10$Wc5nCNkeHOxOFS99B3mS8OSbYjqajM/M.0fuc5MZFajOZC8PayBO.', 'teacher', '2025-05-21 09:46:06');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `students_teacher1`
--
ALTER TABLE `students_teacher1`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `lrn` (`lrn`);

--
-- Indexes for table `students_teacher2`
--
ALTER TABLE `students_teacher2`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `lrn` (`lrn`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `identification` (`identification`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `students_teacher1`
--
ALTER TABLE `students_teacher1`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `students_teacher2`
--
ALTER TABLE `students_teacher2`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
