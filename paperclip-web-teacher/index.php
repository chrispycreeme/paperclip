<?php
// Start the session to manage user login state
session_start();

// Check if the user is already logged in
if (isset($_SESSION['loggedin']) && $_SESSION['loggedin'] === true) {
    // If logged in, redirect to the dashboard
    header("Location: dashboard.php");
    exit; // Stop further script execution
} else {
    // If not logged in, redirect to the login page
    header("Location: login.php");
    exit; // Stop further script execution
}
?>
