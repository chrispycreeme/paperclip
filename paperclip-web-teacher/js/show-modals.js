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

    // Function to open a modal
    function openModal(modal) {
        modal.classList.add('active');
    }

    // Function to close a modal
    function closeModal(modal) {
        modal.classList.remove('active');
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

            studentNameEditModal.textContent = studentName;
            exitCodeInput.value = currentExitCode;
            studentLrnInput.value = studentLrn;

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
});