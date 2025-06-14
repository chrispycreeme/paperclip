<?php
session_start();

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

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
    error_log("Security Alert: Invalid or missing student_table_name in session. Value: " . ($student_table_name ?? 'NULL'));
    die("Error: Invalid student data configuration. Please contact support.");
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'update_exit_code') {
    $lrn = trim($_POST['lrn'] ?? '');
    $newExitCode = trim($_POST['exit_code'] ?? '');

    if (!preg_match('/^\d{6}$/', $newExitCode)) {
        echo json_encode(['status' => 'error', 'message' => 'Exit code must be exactly 6 digits.']);
        $mysqli->close();
        exit;
    }

    $sql = "UPDATE `" . $student_table_name . "` SET exit_code = ? WHERE lrn = ?";

    if ($stmt = $mysqli->prepare($sql)) {
        $stmt->bind_param("ss", $newExitCode, $lrn);
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode(['status' => 'success', 'message' => 'Exit code updated successfully.']);
            } else {
                echo json_encode(['status' => 'error', 'message' => 'Student not found or no change made.']);
            }
        } else {
            error_log("SQL Error (update_exit_code): " . $stmt->error);
            echo json_encode(['status' => 'error', 'message' => 'Error updating exit code: ' . $stmt->error]);
        }
        $stmt->close();
    } else {
        error_log("SQL Prepare Error (update_exit_code): " . $mysqli->error);
        echo json_encode(['status' => 'error', 'message' => 'Error preparing statement: ' . $mysqli->error]);
    }
    $mysqli->close();
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'update_flag_status') {
    $lrn = trim($_POST['lrn'] ?? '');
    $isFlagged = ($_POST['is_flagged'] === 'true') ? TRUE : FALSE;

    $sql = "UPDATE `" . $student_table_name . "` SET flagged_as_cheater = ? WHERE lrn = ?";

    if ($stmt = $mysqli->prepare($sql)) {

        $stmt->bind_param("is", $isFlagged, $lrn);

        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode(['status' => 'success', 'message' => 'Flag status updated successfully.']);
            } else {
                echo json_encode(['status' => 'error', 'message' => 'Student not found or no change made.']);
            }
        } else {
            error_log("SQL Error (update_flag_status): " . $stmt->error);
            echo json_encode(['status' => 'error', 'message' => 'Error updating flag status: ' . $stmt->error]);
        }
        $stmt->close();
    } else {
        error_log("SQL Prepare Error (update_flag_status): " . $mysqli->error);
        echo json_encode(['status' => 'error', 'message' => 'Error preparing flag status statement: ' . $mysqli->error]);
    }
    $mysqli->close();
    exit;
}


if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'reset_session') {
    $sql = "UPDATE `" . $student_table_name . "` SET times_exited = 0, screenshots_taken = 0, keyboard_used = 0, flagged_as_cheater = FALSE";

    if ($stmt = $mysqli->prepare($sql)) {
        if ($stmt->execute()) {
            header("Location: dashboard.php");
            exit;
        } else {
            error_log("SQL Error (reset_session): " . $stmt->error);
            echo "ERROR: Could not reset session data. " . $stmt->error;
        }
        $stmt->close();
    } else {
        error_log("SQL Prepare Error (reset_session): " . $mysqli->error);
        echo "ERROR: Could not prepare statement for reset. " . $mysqli->error;
    }
    $mysqli->close();
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'delete_student') {
    $lrn = trim($_POST['lrn'] ?? '');

    if (empty($lrn)) {
        echo json_encode(['status' => 'error', 'message' => 'LRN is required to delete a student.']);
        $mysqli->close();
        exit;
    }

    $sql = "DELETE FROM `" . $student_table_name . "` WHERE lrn = ?";

    if ($stmt = $mysqli->prepare($sql)) {
        $stmt->bind_param("s", $lrn);
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode(['status' => 'success', 'message' => 'Student deleted successfully.']);
            } else {
                echo json_encode(['status' => 'error', 'message' => 'Student not found or no student was deleted.']);
            }
        } else {
            error_log("SQL Error (delete_student): " . $stmt->error);
            echo json_encode(['status' => 'error', 'message' => 'Error deleting student: ' . $stmt->error]);
        }
        $stmt->close();
    } else {
        error_log("SQL Prepare Error (delete_student): " . $mysqli->error);
        echo json_encode(['status' => 'error', 'message' => 'Error preparing delete statement: ' . $mysqli->error]);
    }
    $mysqli->close();
    exit;
}

$students = [];

$sql = "SELECT lrn, name, times_exited, screenshots_taken, keyboard_used, flagged_as_cheater, exit_code FROM `" . $student_table_name . "`";

if ($stmt = $mysqli->prepare($sql)) {
    if ($stmt->execute()) {
        $result = $stmt->get_result();
        while ($row = $result->fetch_assoc()) {
            $students[] = $row;
        }
    } else {
        error_log("SQL Error (fetch students): " . $stmt->error);
        echo "ERROR: Could not fetch student data. " . $stmt->error;
    }
    $stmt->close();
} else {
    error_log("SQL Prepare Error (fetch students): " . $mysqli->error);
    echo "ERROR: Could not prepare statement for fetching students. " . $mysqli->error;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'add_student') {
    $lrn = trim($_POST['lrn'] ?? '');
    $name = trim($_POST['name'] ?? '');
    $password = trim($_POST['password'] ?? ''); // Get the password from POST

    if (empty($lrn) || empty($name) || empty($password)) {
        echo json_encode(['status' => 'error', 'message' => 'LRN, Name, and Password are required.']);
        $mysqli->close();
        exit;
    }

    // Hash the password
    $hashed_password = password_hash($password, PASSWORD_DEFAULT); // Auto hash like generate_hash.php

    // Initialize other fields with default values
    $times_exited = 0;
    $screenshots_taken = 0;
    $keyboard_used = 0;
    $flagged_as_cheater = FALSE;
    $exit_code = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

    // Modified SQL to include the 'password' column
    $sql = "INSERT INTO `" . $student_table_name . "` (lrn, name, password, times_exited, screenshots_taken, keyboard_used, flagged_as_cheater, exit_code) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

    if ($stmt = $mysqli->prepare($sql)) {
        // Bind the new password parameter 's' (string)
        $stmt->bind_param("sssiiibs", $lrn, $name, $hashed_password, $times_exited, $screenshots_taken, $keyboard_used, $flagged_as_cheater, $exit_code);
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode(['status' => 'success', 'message' => 'Student added successfully.']);
            } else {
                echo json_encode(['status' => 'error', 'message' => 'Failed to add student.']);
            }
        } else {
            error_log("SQL Error (add_student): " . $stmt->error);
            echo json_encode(['status' => 'error', 'message' => 'Error adding student: ' . $stmt->error]);
        }
        $stmt->close();
    } else {
        error_log("SQL Prepare Error (add_student): " . $mysqli->error);
        echo json_encode(['status' => 'error', 'message' => 'Error preparing statement: ' . $mysqli->error]);
    }
    $mysqli->close();
    exit;
}

$mysqli->close();
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Paperclip - Teacher Dashboard</title>
    <link rel="stylesheet" href="css/dashboard.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link
        href="https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&display=swap"
        rel="stylesheet">
    <link rel="stylesheet"
        href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&icon_names=border_color" />
    <link rel="stylesheet"
        href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&icon_names=cached" />
    <link rel="stylesheet"
        href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&icon_names=logout" />
</head>

<body>
    <div class="container">
        <header>
            <div class="logo-container">
                <div class="logo">
                    <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 94 94" fill="#7D59FF">
                        <mask id="mask0_15_33" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="94"
                            height="120">
                            <rect width="94" height="94" fill="#7D59FF" />
                        </mask>
                        <g mask="url(#mask0_15_33)">
                            <path
                                d="M46.0208 86.1667C39.2319 86.1667 33.4548 83.784 28.6895 79.0188C23.9243 74.2535 21.5416 68.4764 21.5416 61.6875V32.5083L5.48328 16.45L10.9666 10.9667L83.0333 83.0334L77.55 88.5167L65.5062 76.4729C63.2215 79.4104 60.3982 81.7604 57.0364 83.5229C53.6746 85.2854 50.0027 86.1667 46.0208 86.1667ZM29.3749 40.3417V61.6875C29.3097 66.3222 30.909 70.2552 34.1729 73.4865C37.4368 76.7177 41.3861 78.3334 46.0208 78.3334C48.9583 78.3334 51.6184 77.6479 54.001 76.2771C56.3836 74.9063 58.3256 73.0785 59.827 70.7938L54.9312 65.8979C53.952 67.334 52.6954 68.4601 51.1614 69.2761C49.6274 70.092 47.9138 70.5 46.0208 70.5C43.018 70.5 40.4722 69.4556 38.3833 67.3667C36.2944 65.2778 35.2499 62.732 35.2499 59.7292V46.2167L29.3749 40.3417ZM43.0833 54.05V59.7292C43.0833 60.5778 43.3607 61.2795 43.9156 61.8344C44.4704 62.3893 45.1722 62.6667 46.0208 62.6667C46.8041 62.6667 47.4732 62.4056 48.0281 61.8834C48.5829 61.3611 48.893 60.7083 48.9583 59.925L43.0833 54.05ZM62.6666 51.5042V23.5H70.5V59.3375L62.6666 51.5042ZM48.9583 37.7958V25.4583C48.893 22.7167 47.9302 20.3993 46.0697 18.5063C44.2093 16.6132 41.9083 15.6667 39.1666 15.6667C37.4694 15.6667 35.9354 16.0583 34.5645 16.8417C33.1937 17.625 32.0513 18.6695 31.1374 19.975L25.5562 14.3938C27.1881 12.3701 29.1791 10.7708 31.5291 9.59584C33.8791 8.42084 36.4249 7.83334 39.1666 7.83334C44.0624 7.83334 48.2239 9.54689 51.651 12.974C55.0781 16.4011 56.7916 20.5625 56.7916 25.4583V45.6292L48.9583 37.7958ZM43.0833 23.5V31.9208L35.2499 24.0875V23.5H43.0833Z"
                                fill="#7D59FF" />
                        </g>
                    </svg>
                </div>
                <div class="app-title">
                    <h1>paperclip</h1>
                    <div class="app-subtitle">anti-cheating app | Teacher's Edition</div>
                </div>
            </div>
            <a href="logout.php" class="logout-btn" style="text-decoration: none;">
                <span class="material-symbols-outlined">
                    logout
                </span>
                Log out
            </a>
        </header>

        <div class="dashboard-header">
            <div class="dashboard-title">
                <h2>Student Analytics</h2>
                <div class="dashboard-subtitle">Session Data of every Student in your class. You may edit their exit
                    codes.</div>
            </div>
            <div class="reset-session-container">
                <div class="reset-recommendation">
                    It is recommended to reset the session per subject period.
                </div>
                <form id="resetSessionForm" action="dashboard.php" method="POST" style="display:inline;">
                    <input type="hidden" name="action" value="reset_session">
                    <button type="button" class="reset-btn" id="resetSessionBtn">
                        <span class="material-symbols-outlined">
                            cached
                        </span>
                        Reset Session
                    </button>
                </form>
            </div>
        </div>
        <div class="search-container">
            <div class="search-box">
                <input type="text" class="search-input" id="studentSearch" placeholder="Search by name or LRN...">
                <svg class="search-icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24"
                    fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="11" cy="11" r="8"></circle>
                    <path d="m21 21-4.35-4.35"></path>
                </svg>
                <button class="clear-search" id="clearSearch">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </button>
            </div>
            <div class="search-stats" id="searchStats">Showing all students</div>
        </div>
        <table class="student-table">
            <thead>
                <tr>
                    <th>Student LRN</th>
                    <th>Student Name</th>
                    <th>Times Exited out of App</th>
                    <th>Screenshots Taken</th>
                    <th>Keyboard Used</th>
                    <th>Flagged As Cheater?</th>
                    <th>Exit Code</th>
                    <th>Delete</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($students)): ?>
                    <tr>
                        <td colspan="7" style="text-align: center;">No student data available for this teacher.</td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($students as $student): ?>
                        <tr data-lrn="<?php echo htmlspecialchars($student['lrn']); ?>">
                            <td class="student-id <?php echo $student['flagged_as_cheater'] ? 'warning-student' : ''; ?>"
                                data-label="Student LRN">
                                <?php echo htmlspecialchars($student['lrn']); ?>
                            </td>
                            <td class="<?php echo $student['flagged_as_cheater'] ? 'warning-student' : ''; ?>"
                                data-label="Student Name">
                                <?php echo htmlspecialchars($student['name']); ?>
                            </td>
                            <td class="<?php echo $student['flagged_as_cheater'] ? 'warning-student' : ''; ?>"
                                data-label="Times Exited out of App">
                                <?php echo htmlspecialchars($student['times_exited']); ?>
                            </td>
                            <td class="<?php echo $student['flagged_as_cheater'] ? 'warning-student' : ''; ?>"
                                data-label="Screenshots Taken">
                                <?php echo htmlspecialchars($student['screenshots_taken']); ?>
                            </td>
                            <td class="<?php echo $student['flagged_as_cheater'] ? 'warning-student' : ''; ?>"
                                data-label="Keyboard Used">
                                <?php echo htmlspecialchars($student['keyboard_used']); ?>
                            </td>
                            <td data-label="Flagged As Cheater?">
                                <div class="checkbox <?php echo $student['flagged_as_cheater'] ? 'checked' : ''; ?>"
                                    data-student-lrn="<?php echo htmlspecialchars($student['lrn']); ?>"
                                    data-is-flagged="<?php echo $student['flagged_as_cheater'] ? 'true' : 'false'; ?>">
                                    <?php if ($student['flagged_as_cheater']): ?>
                                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"
                                            fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                            stroke-linejoin="round">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                    <?php endif; ?>
                                </div>
                            </td>
                            <td data-label="Exit Code">
                                <span class="exit-code-display"
                                    id="exit-code-<?php echo htmlspecialchars($student['lrn']); ?>"><?php echo htmlspecialchars($student['exit_code']); ?></span>
                                <button class="edit-btn" data-student-lrn="<?php echo htmlspecialchars($student['lrn']); ?>"
                                    data-student-name="<?php echo htmlspecialchars($student['name']); ?>"
                                    data-current-exit-code="<?php echo htmlspecialchars($student['exit_code']); ?>">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"
                                        fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                        stroke-linejoin="round">
                                        <path d="M17 3a2.85 2.85 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"></path>
                                    </svg>
                                </button>
                            </td>
                            <td data-label="Actions">
                                <button class="delete-btn" data-student-lrn="<?php echo htmlspecialchars($student['lrn']); ?>"
                                    data-student-name="<?php echo htmlspecialchars($student['name']); ?>"
                                    title="Delete Student">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"
                                        fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                        stroke-linejoin="round">
                                        <polyline points="3 6 5 6 21 6"></polyline>
                                        <path
                                            d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2">
                                        </path>
                                        <line x1="10" y1="11" x2="10" y2="17"></line>
                                        <line x1="14" y1="11" x2="14" y2="17"></line>
                                    </svg>
                                </button>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>

        <div style="display: flex; flex-wrap: wrap; gap: 12px; margin-top: 20px; align-items: center;">
            <a href="export.php" class="export-btn" style="text-decoration: none;">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                    <polyline points="7 10 12 15 17 10"></polyline>
                    <line x1="12" y1="15" x2="12" y2="3"></line>
                </svg>
                Export Session Data
            </a>
            <button class="export-btn" id="importStudentDataBtn">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M4 14.899A7 7 0 0 1 7 14h.007a7 7 0 0 1 6.993 7.899"></path>
                    <path d="M12 16v-9"></path>
                    <path d="m15 10-3-3-3 3"></path>
                </svg>
                Import Student Data
            </button>

            <button class="export-btn" id="addStudentDataBtn">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
                Add Student Data
            </button>
            <!-- <div class="pagination">
                <button>Previous</button>
                <button>Next</button>
            </div> -->
        </div>
    </div>

    <div class="modal-overlay" id="addStudentModal">
        <div class="modal">
            <h2>Add New Student</h2>
            <form id="addStudentForm" method="POST" action="add_student.php">
                <div class="input-label">LRN</div>
                <input type="text" name="lrn" placeholder="Student LRN" required>
                <div class="input-label">Student Name</div>
                <input type="text" name="name" placeholder="Student Name" required>
                <div class="input-label">Password</div> <input type="text" name="password"
                    placeholder="Student Password" required>
                <div class="modal-footer">
                    <button type="button" class="cancel-btn" id="cancelAddStudentBtn">Cancel</button>
                    <button type="submit" class="proceed-btn" id="saveAddStudentBtn">Add Student</button>
                </div>
            </form>
        </div>
    </div>

    <div class="modal-overlay" id="deleteStudentModal">
        <div class="modal">
            <h2>Confirm Deletion</h2>
            <p>Are you sure you want to delete the student <strong id="studentNameToDelete"></strong> (LRN: <span
                    id="studentLrnToDelete"></span>)?</p>
            <div class="notice-box">
                <div class="notice-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path
                            d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z">
                        </path>
                        <line x1="12" y1="9" x2="12" y2="13"></line>
                        <line x1="12" y1="17" x2="12.01" y2="17"></line>
                    </svg>
                </div>
                <div class="notice-content">
                    <strong>Important Notice</strong><br>
                    Once the student is deleted, all their data will be permanently removed and cannot be
                    recovered. Please ensure you have exported any necessary data before proceeding.
                </div>
            </div>
            <div id="deleteStudentMessage" style="margin-top: 10px;"></div>
            <div class="modal-footer">
                <button type="button" class="cancel-btn" id="cancelDeleteStudentBtn">Cancel</button>
                <button type="button" class="proceed-btn danger" id="confirmDeleteStudentBtn">Delete Student</button>
            </div>
        </div>
    </div>

    <div class="modal-overlay" id="resetSessionModal">
        <div class="modal">
            <h2>Reset Session</h2>
            <p>This will reset every count in the current session. Resets are usually done every after subject period to
                avoid duplicate count.</p>

            <div class="notice-box">
                <div class="notice-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path
                            d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z">
                        </path>
                        <line x1="12" y1="9" x2="12" y2="13"></line>
                        <line x1="12" y1="17" x2="12.01" y2="17"></line>
                    </svg>
                </div>
                <div class="notice-content">
                    <strong>Important Notice</strong><br>
                    Once you reset this session, retrieving this session's data is no longer possible. Export the
                    session data before proceeding.
                </div>
            </div>

            <div class="modal-footer">
                <button class="cancel-btn" id="cancelResetBtn">Cancel</button>
                <button class="proceed-btn danger" id="confirmResetBtn">Proceed</button>
            </div>
        </div>
    </div>

    <div class="modal-overlay" id="editExitCodeModal">
        <div class="modal">
            <h2>Edit Exit Code for <span id="studentNameEditModal"></span></h2>
            <p>This will change the selected student's exit code. Don't forget to inform the student subjected.</p>

            <div class="input-label">New Exit Code</div>
            <input type="text" placeholder="6-digit code" id="exitCodeInput">
            <input type="hidden" id="studentLrnInput">
            <div class="modal-footer">
                <button class="cancel-btn" id="cancelEditBtn">Cancel</button>
                <button class="proceed-btn" id="saveExitCodeBtn">Proceed</button>
            </div>
        </div>
    </div>

    <script>
        // This inline script is a diagnostic check to see if HTML is being rendered up to this point.
        console.log('Inline script executed. HTML body is being rendered.');
    </script>
    <script src="js/show-modals.js"></script>
    <script src="js/checkbox-handler.js"></script>
    <script src="js/search-bar-handler.js"></script>
    <script src="js/delete-student.js"></script>
</body>

</html>