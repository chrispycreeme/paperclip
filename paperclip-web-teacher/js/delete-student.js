// delete-student.js
console.log('[DEBUG] delete-student.js loaded'); // Log: Script start

// Get all necessary DOM elements
const deleteStudentModal = document.getElementById('deleteStudentModal');
const cancelDeleteStudentBtn = document.getElementById('cancelDeleteStudentBtn');
const confirmDeleteStudentBtn = document.getElementById('confirmDeleteStudentBtn');
const studentNameToDeleteSpan = document.getElementById('studentNameToDelete');
const studentLrnToDeleteSpan = document.getElementById('studentLrnToDelete');
const deleteStudentMessage = document.getElementById('deleteStudentMessage');
let lrnToDelete = null;

// Log whether the main modal element was found
if (!deleteStudentModal) {
    console.error('[DEBUG] CRITICAL: Delete Student Modal #deleteStudentModal not found in the DOM!');
} else {
    console.log('[DEBUG] Delete Student Modal #deleteStudentModal found:', deleteStudentModal);
}

// Log status of other essential elements for the modal
if (!cancelDeleteStudentBtn) console.warn('[DEBUG] Cancel Delete Button #cancelDeleteStudentBtn not found!');
if (!confirmDeleteStudentBtn) console.warn('[DEBUG] Confirm Delete Button #confirmDeleteStudentBtn not found!');
if (!studentNameToDeleteSpan) console.warn('[DEBUG] Student Name Span #studentNameToDelete not found!');
if (!studentLrnToDeleteSpan) console.warn('[DEBUG] Student LRN Span #studentLrnToDelete not found!');
if (!deleteStudentMessage) console.warn('[DEBUG] Delete Student Message Div #deleteStudentMessage not found!');


const studentTableBody = document.querySelector('.student-table tbody');

if (studentTableBody) {
    console.log('[DEBUG] Student table body (.student-table tbody) found. Attaching click listener.');
    studentTableBody.addEventListener('click', function (event) {
        console.log('[DEBUG] Click detected on table body. Clicked element:', event.target);

        const targetButton = event.target.closest('.delete-btn'); // Correctly finds the button even if SVG is clicked
        console.log('[DEBUG] Attempting to find .delete-btn. Found:', targetButton);

        if (targetButton) {
            console.log('[DEBUG] Delete button was clicked:', targetButton);
            lrnToDelete = targetButton.dataset.studentLrn;
            const studentName = targetButton.dataset.studentName;

            console.log('[DEBUG] LRN to delete:', lrnToDelete);
            console.log('[DEBUG] Student name to delete:', studentName);

            if (studentNameToDeleteSpan) studentNameToDeleteSpan.textContent = studentName;
            if (studentLrnToDeleteSpan) studentLrnToDeleteSpan.textContent = lrnToDelete;
            if (deleteStudentMessage) deleteStudentMessage.textContent = ''; // Clear previous messages

            if (deleteStudentModal) {
                console.log('[DEBUG] Attempting to display delete modal by adding .active class.');
                deleteStudentModal.classList.add('active'); // Use class to show modal
                console.log('[DEBUG] Delete modal classList:', deleteStudentModal.classList);
            } else {
                console.error('[DEBUG] Cannot display modal because deleteStudentModal element was not found earlier.');
            }
        } else {
            console.log('[DEBUG] Clicked target was not a .delete-btn or its child.');
        }
    });
} else {
    console.error('[DEBUG] CRITICAL: Student table body .student-table tbody not found! Cannot attach delete listener.');
}

if (cancelDeleteStudentBtn) {
    console.log('[DEBUG] Cancel delete button #cancelDeleteStudentBtn found. Attaching click listener.');
    cancelDeleteStudentBtn.addEventListener('click', function () {
        console.log('[DEBUG] Cancel delete button clicked.');
        if (deleteStudentModal) {
            console.log('[DEBUG] Hiding delete modal by removing .active class.');
            deleteStudentModal.classList.remove('active'); // Use class to hide modal
        }
        lrnToDelete = null; // Reset LRN
    });
} else {
    console.warn('[DEBUG] #cancelDeleteStudentBtn not found, cannot attach its click listener.');
}

if (confirmDeleteStudentBtn) {
    console.log('[DEBUG] Confirm delete button #confirmDeleteStudentBtn found. Attaching click listener.');
    confirmDeleteStudentBtn.addEventListener('click', function () {
        console.log('[DEBUG] Confirm delete button clicked.');
        if (lrnToDelete) {
            console.log(`[DEBUG] Proceeding with delete for LRN: ${lrnToDelete}`);
            confirmDeleteStudentBtn.disabled = true;
            confirmDeleteStudentBtn.textContent = 'Deleting...';
            if (deleteStudentMessage) deleteStudentMessage.textContent = '';

            // Fetch API call to delete the student
            fetch('dashboard.php', { // Ensure this path is correct from the browser's perspective
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: `action=delete_student&lrn=${encodeURIComponent(lrnToDelete)}`
            })
            .then(response => {
                console.log('[DEBUG] Fetch response received. Status:', response.status);
                if (!response.ok) {
                    // Try to get more error info from the response body
                    return response.text().then(text => {
                        console.error(`[DEBUG] Server error response body: ${text}`);
                        throw new Error(`Server responded with ${response.status}: ${text || response.statusText}`);
                    });
                }
                return response.json(); // Attempt to parse JSON
            })
            .then(data => {
                console.log('[DEBUG] Delete response data from server:', data);
                if (data.status === 'success') {
                    if (deleteStudentMessage) {
                        deleteStudentMessage.textContent = data.message || 'Student deleted successfully.';
                        deleteStudentMessage.style.color = 'green';
                    }
                    // Remove the row from the table
                    // This relies on the `data-lrn` attribute being on the `<tr>` element
                    const rowToDelete = document.querySelector(`tr[data-lrn="${lrnToDelete}"]`);
                    if (rowToDelete) {
                        console.log('[DEBUG] Table row to delete found:', rowToDelete);
                        rowToDelete.remove();
                        console.log('[DEBUG] Table row removed.');
                    } else {
                        console.warn(`[DEBUG] Could not find table row with data-lrn="${lrnToDelete}" to remove.`);
                    }

                    // Check if table body is empty and update if necessary
                    const tbody = document.querySelector('.student-table tbody');
                    if (tbody && tbody.children.length === 0) {
                        console.log('[DEBUG] Table body is empty, adding "No student data" message.');
                        const numColumns = document.querySelector('.student-table thead tr')?.children.length || 7; // Fallback column count
                        tbody.innerHTML = `<tr><td colspan="${numColumns}" style="text-align: center;">No student data available for this teacher.</td></tr>`;
                    }

                    // Hide modal after a delay
                    setTimeout(() => {
                        if (deleteStudentModal) {
                            console.log('[DEBUG] Hiding modal after successful deletion.');
                            deleteStudentModal.classList.remove('active');
                        }
                    }, 1500);
                } else {
                    if (deleteStudentMessage) {
                        deleteStudentMessage.textContent = 'Error: ' + (data.message || 'Unknown error from server.');
                        deleteStudentMessage.style.color = 'red';
                    }
                    console.error('[DEBUG] Server returned error status:', data.message);
                }
            })
            .catch(error => {
                console.error('[DEBUG] Fetch Error during delete:', error);
                if (deleteStudentMessage) {
                    deleteStudentMessage.textContent = 'An error occurred: ' + error.message;
                    deleteStudentMessage.style.color = 'red';
                }
            })
            .finally(() => {
                console.log('[DEBUG] Delete operation fetch call finished.');
                confirmDeleteStudentBtn.disabled = false;
                confirmDeleteStudentBtn.textContent = 'Delete Student';
                // Do not reset lrnToDelete here, only on cancel or successful modal close
            });
        } else {
            console.warn('[DEBUG] lrnToDelete is null on confirm delete click. Cannot proceed.');
        }
    });
} else {
    console.warn('[DEBUG] #confirmDeleteStudentBtn not found, cannot attach its click listener.');
}

// Event listener for closing modal if overlay (background) is clicked
if (deleteStudentModal) {
    console.log('[DEBUG] Delete modal overlay click listener for closing is being attached.');
    deleteStudentModal.addEventListener('click', function (event) {
        // If the click is directly on the overlay (not its children like the modal content)
        if (event.target === deleteStudentModal) {
            console.log('[DEBUG] Delete modal overlay clicked, hiding modal.');
            deleteStudentModal.classList.remove('active');
            lrnToDelete = null; // Reset LRN
        }
    });
}
