// js/modal-handler.js
console.log('--- modal-handler.js file started execution. ---');

document.addEventListener('DOMContentLoaded', () => {
    console.log('modal-handler.js script loaded and DOMContentLoaded event fired.');

    // Get references to modal elements
    const resetSessionBtn = document.getElementById('resetSessionBtn');
    const resetSessionModal = document.getElementById('resetSessionModal');
    const cancelResetBtn = document.getElementById('cancelResetBtn');
    const confirmResetBtn = document.getElementById('confirmResetBtn');
    const resetSessionForm = document.getElementById('resetSessionForm'); // Get the form element

    const editExitCodeModal = document.getElementById('editExitCodeModal');
    const cancelEditBtn = document.getElementById('cancelEditBtn');
    const saveExitCodeBtn = document.getElementById('saveExitCodeBtn');
    const editButtons = document.querySelectorAll('.edit-btn');

    const studentNameEditModal = document.getElementById('studentNameEditModal');
    const exitCodeInput = document.getElementById('exitCodeInput');
    const studentLrnInput = document.getElementById('studentLrnInput');

    // New modal elements for Add Student Data
    const addStudentModal = document.getElementById('addStudentModal');
    const addStudentDataBtn = document.getElementById('addStudentDataBtn');
    const cancelAddStudentBtn = document.getElementById('cancelAddStudentBtn');
    const addStudentForm = document.getElementById('addStudentForm'); // If using AJAX for adding

    // New button for Import Student Data
    const importStudentDataBtn = document.getElementById('importStudentDataBtn');

    // Function to open a modal
    function openModal(modal) {
        modal.classList.add('active'); // Assuming 'active' class controls visibility
        modal.style.display = 'flex'; // Ensure it's displayed as a flex container
    }

    // Function to close a modal
    function closeModal(modal) {
        modal.classList.remove('active');
        modal.style.display = 'none'; // Hide it
    }

    // Event listener for "Reset Session" button
    if (resetSessionBtn) {
        resetSessionBtn.addEventListener('click', (event) => {
            event.preventDefault(); // Prevent the default form submission
            console.log('Reset Session button clicked, opening modal.');
            openModal(resetSessionModal);
        });
    }

    // Event listener for "Cancel" button in Reset Session Modal
    if (cancelResetBtn) {
        cancelResetBtn.addEventListener('click', () => {
            console.log('Reset Session modal: Cancel clicked.');
            closeModal(resetSessionModal);
        });
    }

    // Event listener for "Proceed" button in Reset Session Modal
    if (confirmResetBtn) {
        confirmResetBtn.addEventListener('click', () => {
            console.log('Reset Session modal: Proceed clicked. Submitting form.');
            if (resetSessionForm) {
                resetSessionForm.submit(); // Explicitly submit the form
            }
            closeModal(resetSessionModal); // Close modal after submission
        });
    }

    // Event listeners for all "Edit" buttons
    editButtons.forEach(button => {
        button.addEventListener('click', (event) => {
            const studentLrn = event.currentTarget.dataset.studentLrn;
            const studentName = event.currentTarget.dataset.studentName;
            const currentExitCode = event.currentTarget.dataset.currentExitCode;

            if (studentNameEditModal) studentNameEditModal.textContent = studentName;
            if (exitCodeInput) exitCodeInput.value = currentExitCode;
            if (studentLrnInput) studentLrnInput.value = studentLrn;

            openModal(editExitCodeModal);
        });
    });

    // Event listener for "Cancel" button in Edit Exit Code Modal
    if (cancelEditBtn) {
        cancelEditBtn.addEventListener('click', () => {
            closeModal(editExitCodeModal);
        });
    }

    // Event listener for "Proceed" (Save) button in Edit Exit Code Modal
    if (saveExitCodeBtn) {
        saveExitCodeBtn.addEventListener('click', async () => { // Made async for fetch
            const newExitCode = exitCodeInput.value.trim(); // Trim whitespace
            const studentLrnToUpdate = studentLrnInput.value;

            // Client-side validation for 6 digits
            if (!/^\d{6}$/.test(newExitCode)) {
                alert('Error: Exit code must be exactly 6 digits.');
                console.warn('Client-side validation failed: Exit code not 6 digits.');
                return; // Stop execution if validation fails
            }

            if (studentLrnToUpdate && newExitCode) {
                try {
                    const response = await fetch('dashboard.php', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded',
                        },
                        body: new URLSearchParams({
                            action: 'update_exit_code',
                            lrn: studentLrnToUpdate,
                            exit_code: newExitCode
                        }).toString(),
                    });

                    const data = await response.json();

                    if (data.status === 'success') {
                        const exitCodeDisplayElement = document.getElementById(`exit-code-${studentLrnToUpdate}`);
                        if (exitCodeDisplayElement) {
                            exitCodeDisplayElement.textContent = newExitCode;
                            // Update the data-current-exit-code attribute on the edit button as well
                            const currentEditButton = document.querySelector(`.edit-btn[data-student-lrn="${studentLrnToUpdate}"]`);
                            if (currentEditButton) {
                                currentEditButton.dataset.currentExitCode = newExitCode;
                            }
                        }
                        closeModal(editExitCodeModal);
                        alert(data.message); // Inform the user of success
                        console.log('Update successful:', data.message);
                        location.reload(); // Reload the page to refresh student data table
                    } else {
                        alert('Error: ' + data.message); // Show error message from server
                        console.error('Server error updating exit code:', data.message);
                    }
                } catch (error) {
                    console.error('Fetch error:', error);
                    alert('An error occurred while trying to update the exit code. Please check console for details.');
                }
            } else {
                console.warn("LRN or New Exit Code is missing before sending AJAX request.");
                alert("Missing student LRN or exit code. Cannot proceed with update.");
            }
        });
    }

    // Event listeners for the new "Add Student Data" modal
    if (addStudentDataBtn) {
        addStudentDataBtn.addEventListener('click', () => {
            openModal(addStudentModal);
        });
    }

    if (cancelAddStudentBtn) {
        cancelAddStudentBtn.addEventListener('click', () => {
            closeModal(addStudentModal);
            if (addStudentForm) addStudentForm.reset(); // Clear form on cancel
        });
    }

    // If you decide to handle adding student via AJAX on dashboard.php
    if (addStudentForm) {
        addStudentForm.addEventListener('submit', async (e) => {
            e.preventDefault(); // Prevent default form submission

            const lrn = addStudentForm.querySelector('input[name="lrn"]').value;
            const name = addStudentForm.querySelector('input[name="name"]').value;
            const password = addStudentForm.querySelector('input[name="password"]').value;

            try {
                const response = await fetch('dashboard.php', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded'
                    },
                    body: new URLSearchParams({
                        action: 'add_student',
                        lrn: lrn,
                        name: name,
                        password: password
                    }).toString()
                });
                
                const data = await response.json();

                if (data.status === 'success') {
                    alert(data.message);
                    closeModal(addStudentModal); // Close the modal on success
                    location.reload(); // Reload to show new student
                } else {
                    alert('Error: ' + data.message);
                }
            } catch (error) {
                console.error('Error:', error);
                alert('An error occurred while adding the student.');
            }
        });
    }

    // Event listener for the import button (to redirect to import_students.php)
    if (importStudentDataBtn) {
        importStudentDataBtn.addEventListener('click', () => {
            window.location.href = 'import_students.php'; // Redirect to the import page
        });
    }

    // Close modals if clicking outside (on the overlay)
    if (resetSessionModal) {
        resetSessionModal.addEventListener('click', (event) => {
            if (event.target === resetSessionModal) {
                closeModal(resetSessionModal);
            }
        });
    }

    if (editExitCodeModal) {
        editExitCodeModal.addEventListener('click', (event) => {
            if (event.target === editExitCodeModal) {
                closeModal(editExitCodeModal);
            }
        });
    }

    // Add this for the new add student modal too
    if (addStudentModal) {
        addStudentModal.addEventListener('click', (event) => {
            if (event.target === addStudentModal) {
                closeModal(addStudentModal);
            }
        });
    }
});