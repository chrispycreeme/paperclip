<?php
// student_login.php
header("Content-Type: application/json");
require_once 'db_connect.php'; // Include your database connection

$lrn = $_POST['lrn'] ?? '';
$password = $_POST['password'] ?? '';
$teacher_table_name = $_POST['teacher_table_name'] ?? ''; // Expecting this from Flutter app

if (empty($lrn) || empty($password) || empty($teacher_table_name)) {
    echo json_encode(["success" => false, "message" => "LRN, password, and teacher table name are required."]);
    $mysqli->close();
    exit();
}

// --- IMPORTANT SECURITY: Validate teacher_table_name strictly ---
// This is crucial to prevent SQL injection for table names.
$allowed_student_tables = [
    'students_teacher1',
    'students_teacher2'
    // Add all your expected teacher-specific student table names here
];

if (!in_array($teacher_table_name, $allowed_student_tables)) {
    error_log("Security Alert: Invalid teacher_table_name in student_login.php. Value: " . ($teacher_table_name ?? 'NULL'));
    echo json_encode(["success" => false, "message" => "Invalid teacher table specified."]);
    $mysqli->close();
    exit();
}

// Query the specific student table for the LRN, name, and hashed password
// The backticks around $teacher_table_name are important for dynamic table names.
$sql = "SELECT lrn, name, password FROM `" . $teacher_table_name . "` WHERE lrn = ?";

if ($stmt = $mysqli->prepare($sql)) {
    $stmt->bind_param("s", $lrn);
    if ($stmt->execute()) {
        $result = $stmt->get_result();
        if ($result->num_rows == 1) {
            $row = $result->fetch_assoc();
            $hashed_password = $row['password'];
            $student_name = $row['name']; // Get student name from the table

            if (password_verify($password, $hashed_password)) {
                // Login successful
                echo json_encode([
                    "success" => true,
                    "message" => "Login successful.",
                    "student_lrn" => $row['lrn'],
                    "student_name" => $student_name, // Include student name in response
                    "teacher_table_name" => $teacher_table_name // Return it for confirmation
                ]);
            } else {
                echo json_encode(["success" => false, "message" => "Invalid LRN or password."]);
            }
        } else {
            echo json_encode(["success" => false, "message" => "Invalid LRN or password."]);
        }
    } else {
        error_log("SQL Error (student_login execute): " . $stmt->error);
        echo json_encode(["success" => false, "message" => "Database query error."]);
    }
    $stmt->close();
} else {
    error_log("SQL Prepare Error (student_login): " . $mysqli->error);
    echo json_encode(["success" => false, "message" => "Server error preparing statement."]);
}
$mysqli->close();
?>