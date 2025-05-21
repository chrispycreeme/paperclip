<?php
session_start();
require_once 'db_connect.php';

if (!isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true) {
    header("Location: login.php");
    exit;
}

$student_table_name = $_SESSION['student_table_name'] ?? null;

$allowed_student_tables = [
    'students_teacher1',
    'students_teacher2'
];

if (!$student_table_name || !in_array($student_table_name, $allowed_student_tables)) {
    error_log("Security Alert: Invalid or missing student_table_name in session during export. Value: " . ($student_table_name ?? 'NULL'));
    die("Error: Invalid student data configuration for export. Please contact support.");
}

// Fetch student data
$students = [];
$sql = "SELECT lrn, name, times_exited, screenshots_taken, keyboard_used, flagged_as_cheater, exit_code FROM `" . $student_table_name . "`";

if ($stmt = $mysqli->prepare($sql)) {
    if ($stmt->execute()) {
        $result = $stmt->get_result();
        while ($row = $result->fetch_assoc()) {
            $students[] = $row;
        }
    } else {
        error_log("SQL Error (export fetch students): " . $stmt->error);
        die("ERROR: Could not fetch student data for export. " . $stmt->error);
    }
    $stmt->close();
} else {
    error_log("SQL Prepare Error (export fetch students): " . $mysqli->error);
    die("ERROR: Could not prepare statement for export. " . $mysqli->error);
}

$mysqli->close();

// Generate CSV
header('Content-Type: text/csv');
header('Content-Disposition: attachment; filename="student_session_data_' . date('Y-m-d_H-i-s') . '.csv"');

$output = fopen('php://output', 'w');

// Add CSV headers
fputcsv($output, ['Student LRN', 'Student Name', 'Times Exited out of App', 'Screenshots Taken', 'Keyboard Used', 'Flagged As Cheater?', 'Exit Code']);

// Add student data to CSV
foreach ($students as $student) {
    fputcsv($output, [
        $student['lrn'],
        $student['name'],
        $student['times_exited'],
        $student['screenshots_taken'],
        $student['keyboard_used'],
        $student['flagged_as_cheater'] ? 'Yes' : 'No', // Convert boolean to string for CSV
        $student['exit_code']
    ]);
}

fclose($output);
exit;

?>