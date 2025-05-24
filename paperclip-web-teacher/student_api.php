<?php
// student_api.php
header("Content-Type: application/json");
require_once 'db_connect.php'; // Include your database connection

// You need a secure way to identify the student and their associated teacher's table.
// This is the MOST CRITICAL SECURITY ASPECT.
// For now, I'll assume student_id and teacher_table_name are passed,
// but in a real app, these should be derived from a secure authentication token
// provided by the student login system.

$student_id = $_POST['student_id'] ?? $_GET['student_id'] ?? '';
$teacher_table_name = $_POST['teacher_table_name'] ?? $_GET['teacher_table_name'] ?? ''; // This needs to come from the app securely!

// --- IMPORTANT SECURITY: Validate teacher_table_name strictly ---
$allowed_student_tables = [
    'students_teacher1',
    'students_teacher2'
    // Add all your expected teacher-specific student table names here, synced with dashboard.php
];

if (empty($student_id) || empty($teacher_table_name) || !in_array($teacher_table_name, $allowed_student_tables)) {
    error_log("Security Alert: Invalid or missing student_id or teacher_table_name in student_api.php. Student ID: " . ($student_id ?? 'NULL') . ", Table: " . ($teacher_table_name ?? 'NULL'));
    echo json_encode(["success" => false, "message" => "Invalid request parameters or unauthorized access."]);
    $mysqli->close();
    exit();
}

// Handle GET request to retrieve analytics for a student
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['action']) && $_GET['action'] === 'get_analytics') {
    $sql = "SELECT screenshots_taken, times_exited, keyboard_used FROM `" . $teacher_table_name . "` WHERE lrn = ?";

    if ($stmt = $mysqli->prepare($sql)) {
        $stmt->bind_param("s", $student_id);
        if ($stmt->execute()) {
            $result = $stmt->get_result();
            if ($result->num_rows > 0) {
                $row = $result->fetch_assoc();
                echo json_encode(["success" => true, "data" => $row]);
            } else {
                // If student not found, return default counts (0) and indicate not found
                echo json_encode(["success" => false, "message" => "Student not found in this class.", "data" => ["screenshots_taken" => 0, "times_exited" => 0, "keyboard_used" => 0]]);
            }
        } else {
            error_log("SQL Error (get_analytics): " . $stmt->error);
            echo json_encode(["success" => false, "message" => "Database query error."]);
        }
        $stmt->close();
    } else {
        error_log("SQL Prepare Error (get_analytics): " . $mysqli->error);
        echo json_encode(["success" => false, "message" => "Server error preparing statement."]);
    }
    $mysqli->close();
    exit();
}

// Handle POST request to update analytics for a student
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'update_analytics') {
    $screenshots_taken_delta = filter_var($_POST['screenshots_taken_delta'] ?? 0, FILTER_VALIDATE_INT);
    $times_exited_delta = filter_var($_POST['times_exited_delta'] ?? 0, FILTER_VALIDATE_INT);
    $keyboard_opened_delta = filter_var($_POST['keyboard_opened_delta'] ?? 0, FILTER_VALIDATE_INT);

    // Basic validation for deltas
    if ($screenshots_taken_delta === false || $times_exited_delta === false || $keyboard_opened_delta === false) {
        echo json_encode(["success" => false, "message" => "Invalid delta values."]);
        $mysqli->close();
        exit();
    }

    $sql = "UPDATE `" . $teacher_table_name . "` SET
                screenshots_taken = screenshots_taken + ?,
                times_exited = times_exited + ?,
                keyboard_used = keyboard_used + ?
            WHERE lrn = ?";

    if ($stmt = $mysqli->prepare($sql)) {
        $stmt->bind_param("iiis", $screenshots_taken_delta, $times_exited_delta, $keyboard_opened_delta, $student_id);
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode(["success" => true, "message" => "Analytics updated."]);
            } else {
                // This means the student LRN was not found in the specified teacher's table
                echo json_encode(["success" => false, "message" => "Student LRN not found or no change made."]);
            }
        } else {
            error_log("SQL Error (update_analytics): " . $stmt->error);
            echo json_encode(["success" => false, "message" => "Database update error."]);
        }
        $stmt->close();
    } else {
        error_log("SQL Prepare Error (update_analytics): " . $mysqli->error);
        echo json_encode(["success" => false, "message" => "Server error preparing statement."]);
    }
    $mysqli->close();
    exit();
}

// --- NEW: Handle GET request to retrieve exit code for a student ---
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['action']) && $_GET['action'] === 'get_exit_code') {
    $sql = "SELECT exit_code FROM `" . $teacher_table_name . "` WHERE lrn = ?";

    if ($stmt = $mysqli->prepare($sql)) {
        $stmt->bind_param("s", $student_id);
        if ($stmt->execute()) {
            $result = $stmt->get_result();
            if ($result->num_rows > 0) {
                $row = $result->fetch_assoc();
                echo json_encode(["success" => true, "data" => ["exit_code" => $row['exit_code']]]);
            } else {
                echo json_encode(["success" => false, "message" => "Student LRN not found or exit code not set."]);
            }
        } else {
            error_log("SQL Error (get_exit_code): " . $stmt->error);
            echo json_encode(["success" => false, "message" => "Database query error."]);
        }
        $stmt->close();
    } else {
        error_log("SQL Prepare Error (get_exit_code): " . $mysqli->error);
        echo json_encode(["success" => false, "message" => "Server error preparing statement."]);
    }
    $mysqli->close();
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'background_heartbeat') {
    $status = $_POST['status'] ?? 'unknown';
    // You can log this heartbeat, update a 'last_seen' timestamp in your student table,
    // or simply acknowledge it. For now, we'll just acknowledge.

    // Example: Update a 'last_heartbeat_at' timestamp in the student's table
    // You would need to add a 'last_heartbeat_at' column (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
    // to your students_teacherX tables for this to be useful.
    /*
    $sql_heartbeat = "UPDATE `" . $teacher_table_name . "` SET last_heartbeat_at = CURRENT_TIMESTAMP WHERE lrn = ?";
    if ($stmt_heartbeat = $mysqli->prepare($sql_heartbeat)) {
        $stmt_heartbeat->bind_param("s", $student_id);
        $stmt_heartbeat->execute();
        $stmt_heartbeat->close();
    } else {
        error_log("SQL Prepare Error (background_heartbeat): " . $mysqli->error);
    }
    */

    echo json_encode(["success" => true, "message" => "Heartbeat received for $student_id, status: $status"]);
    $mysqli->close();
    exit();
}

// If no action is specified or recognized
echo json_encode(["success" => false, "message" => "Invalid API action."]);
$mysqli->close();
?>
