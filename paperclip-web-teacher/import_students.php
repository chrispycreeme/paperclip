<?php
session_start();

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once 'db_connect.php';

// Check if user is logged in
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

$message = '';
$messageType = '';

// Handle file upload
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['csv_file'])) {
    $uploadedFile = $_FILES['csv_file'];

    // Check for upload errors
    if ($uploadedFile['error'] !== UPLOAD_ERR_OK) {
        $message = 'Error uploading file. Please try again.';
        $messageType = 'error';
    } elseif (strtolower(pathinfo($uploadedFile['name'], PATHINFO_EXTENSION)) !== 'csv') {
        $message = 'Please upload a CSV file only.';
        $messageType = 'error';
    } else {
        // Process the CSV file
        $csvData = [];
        $handle = fopen($uploadedFile['tmp_name'], 'r');

        if ($handle !== false) {
            // Skip header row
            $header = fgetcsv($handle);

            // Expected headers: LRN, Name, Password
            $expectedHeaders = ['lrn', 'name', 'password'];
            $headerMap = [];

            // Map headers (case-insensitive)
            foreach ($header as $index => $headerName) {
                // Remove BOM if present
                $cleanHeader = strtolower(trim(preg_replace('/^\xEF\xBB\xBF/', '', $headerName)));
                if (in_array($cleanHeader, $expectedHeaders)) {
                    $headerMap[$cleanHeader] = $index;
                }
            }

            // Check if all required headers are present
            $missingHeaders = array_diff($expectedHeaders, array_keys($headerMap));
            if (!empty($missingHeaders)) {
                $message = 'Missing required columns: ' . implode(', ', $missingHeaders) . '. Expected columns: LRN, Name, Password';
                $messageType = 'error';
            } else {
                $successCount = 0;
                $errorCount = 0;
                $errors = [];

                // Process each row
                while (($row = fgetcsv($handle)) !== false) {
                    $lrn = trim($row[$headerMap['lrn']] ?? '');
                    $name = trim($row[$headerMap['name']] ?? '');
                    $password = trim($row[$headerMap['password']] ?? '');

                    // Validate required fields
                    if (empty($lrn) || empty($name) || empty($password)) {
                        $errorCount++;
                        $errors[] = "Row with LRN '$lrn': Missing required fields";
                        continue;
                    }

                    // Hash the password
                    $hashed_password = password_hash($password, PASSWORD_DEFAULT);

                    // Initialize other fields with default values
                    $times_exited = 0;
                    $screenshots_taken = 0;
                    $keyboard_used = 0;
                    $flagged_as_cheater = FALSE;
                    $exit_code = '';

                    // Insert student into database
                    $sql = "INSERT INTO `" . $student_table_name . "` (lrn, name, password, times_exited, screenshots_taken, keyboard_used, flagged_as_cheater, exit_code) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

                    if ($stmt = $mysqli->prepare($sql)) {
                        $stmt->bind_param("sssiiibs", $lrn, $name, $hashed_password, $times_exited, $screenshots_taken, $keyboard_used, $flagged_as_cheater, $exit_code);

                        if ($stmt->execute()) {
                            $successCount++;
                        } else {
                            $errorCount++;
                            // Check if it's a duplicate entry error
                            if ($stmt->errno === 1062) {
                                $errors[] = "LRN '$lrn' already exists";
                            } else {
                                $errors[] = "Error adding LRN '$lrn': " . $stmt->error;
                            }
                        }
                        $stmt->close();
                    } else {
                        $errorCount++;
                        $errors[] = "Database error for LRN '$lrn'";
                    }
                }

                // Prepare success/error message
                if ($successCount > 0 && $errorCount === 0) {
                    $message = "Successfully imported $successCount students.";
                    $messageType = 'success';
                } elseif ($successCount > 0 && $errorCount > 0) {
                    $message = "Imported $successCount students successfully. $errorCount failed.";
                    if (!empty($errors)) {
                        $message .= " Errors: " . implode(', ', array_slice($errors, 0, 5));
                        if (count($errors) > 5) {
                            $message .= " (and " . (count($errors) - 5) . " more)";
                        }
                    }
                    $messageType = 'warning';
                } else {
                    $message = "Import failed. No students were added. Errors: " . implode(', ', array_slice($errors, 0, 5));
                    $messageType = 'error';
                }
            }

            fclose($handle);
        } else {
            $message = 'Could not read the uploaded file.';
            $messageType = 'error';
        }
    }
}

$mysqli->close();
?>

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Import Students - Paperclip</title>
    <link rel="stylesheet" href="css/dashboard.css">
    <link rel="stylesheet" href="css/import.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet"
        href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&icon_names=logout" />
    <link
        href="https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&display=swap"
        rel="stylesheet">
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
                <span class="material-symbols-outlined">logout</span>
                Log out
            </a>
        </header>

        <div class="import-container">
            <a href="dashboard.php" class="back-btn">← Back to Dashboard</a>

            <div class="import-card">
                <h2>Import Student Data</h2>
                <p>Upload a CSV file containing student information to add multiple students at once.</p>

                <?php if (!empty($message)): ?>
                    <div class="message-box message-<?php echo $messageType; ?>">
                        <?php echo htmlspecialchars($message); ?>
                    </div>
                <?php endif; ?>

                <form method="POST" enctype="multipart/form-data" id="uploadForm">
                    <div class="file-upload-area" id="fileUploadArea">
                        <svg class="upload-icon" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                            stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                        </svg>
                        <p><strong>Click to select a CSV file</strong> or drag and drop it here</p>
                        <p style="color: #666; font-size: 14px;">Maximum file size: 2MB</p>
                        <input type="file" name="csv_file" accept=".csv" required class="file-input" id="fileInput">
                        <button type="button" class="upload-btn" onclick="document.getElementById('fileInput').click()">
                            Choose File
                        </button>
                    </div>

                    <div id="fileInfo"
                        style="display: none; margin: 10px 0; padding: 10px; background: #e9ecef; border-radius: 6px;">
                        <strong>Selected file:</strong> <span id="fileName"></span>
                    </div>

                    <button type="submit" class="upload-btn" style="width: 100%; margin-top: 20px;" id="submitBtn"
                        disabled>
                        Import Students
                    </button>
                </form>
            </div>

            <div class="import-card">
                <h3>CSV Format Requirements</h3>
                <div class="instructions">
                    <p><strong>Your CSV file must contain the following columns (case-insensitive):</strong></p>
                    <ul>
                        <li><strong>LRN</strong> - Student's Learning Reference Number</li>
                        <li><strong>Name</strong> - Student's full name</li>
                        <li><strong>Password</strong> - Student's login password</li>
                    </ul>

                    <h4>Sample CSV Format:</h4>
                    <table class="sample-table">
                        <thead>
                            <tr>
                                <th>LRN</th>
                                <th>Name</th>
                                <th>Password</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>123456789012</td>
                                <td>John Doe</td>
                                <td>john123</td>
                            </tr>
                            <tr>
                                <td>123456789013</td>
                                <td>Jane Smith</td>
                                <td>jane456</td>
                            </tr>
                            <tr>
                                <td>123456789014</td>
                                <td>Bob Johnson</td>
                                <td>bob789</td>
                            </tr>
                        </tbody>
                    </table>

                    <p><strong>Important Notes:</strong></p>
                    <ul>
                        <li>The first row should contain column headers</li>
                        <li>All fields are required for each student</li>
                        <li>Duplicate LRNs will be skipped</li>
                        <li>Passwords will be automatically encrypted</li>
                        <li>Student tracking data will be initialized to zero</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>

    <script>
        const fileInput = document.getElementById('fileInput');
        const fileUploadArea = document.getElementById('fileUploadArea');
        const fileInfo = document.getElementById('fileInfo');
        const fileName = document.getElementById('fileName');
        const submitBtn = document.getElementById('submitBtn');

        // Handle file selection
        fileInput.addEventListener('change', function (e) {
            if (e.target.files.length > 0) {
                const file = e.target.files[0];
                fileName.textContent = file.name;
                fileInfo.style.display = 'block';
                submitBtn.disabled = false;
            } else {
                fileInfo.style.display = 'none';
                submitBtn.disabled = true;
            }
        });

        // Handle drag and drop
        fileUploadArea.addEventListener('click', function (e) {
            if (e.target !== fileInput) {
                fileInput.click();
            }
        });

        fileUploadArea.addEventListener('dragover', function (e) {
            e.preventDefault();
            fileUploadArea.classList.add('dragover');
        });

        fileUploadArea.addEventListener('dragleave', function (e) {
            e.preventDefault();
            fileUploadArea.classList.remove('dragover');
        });

        fileUploadArea.addEventListener('drop', function (e) {
            e.preventDefault();
            fileUploadArea.classList.remove('dragover');

            const files = e.dataTransfer.files;
            if (files.length > 0) {
                fileInput.files = files;
                const event = new Event('change');
                fileInput.dispatchEvent(event);
            }
        });

        // Handle form submission
        document.getElementById('uploadForm').addEventListener('submit', function () {
            submitBtn.textContent = 'Importing...';
            submitBtn.disabled = true;
        });
    </script>
</body>

</html>