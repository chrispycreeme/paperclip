<?php
// Database connection parameters
define('DB_SERVER', 'localhost'); // Your database server (e.g., 'localhost' or an IP address)
define('DB_USERNAME', 'root');     // Your database username
define('DB_PASSWORD', 'root');         // Your database password
define('DB_NAME', 'paperclip_db'); // The name of your database

// Attempt to connect to MySQL database
$mysqli = new mysqli(DB_SERVER, DB_USERNAME, DB_PASSWORD, DB_NAME);

// Check connection
if ($mysqli->connect_error) {
    die("ERROR: Could not connect. " . $mysqli->connect_error);
}
?>
