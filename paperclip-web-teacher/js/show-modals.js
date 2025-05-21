const resetSessionBtn = document.getElementById('resetSessionBtn');
const resetSessionModal = document.getElementById('resetSessionModal');
const cancelResetBtn = document.getElementById('cancelResetBtn');

resetSessionBtn.addEventListener('click', () => {
    resetSessionModal.classList.add('active');
});

cancelResetBtn.addEventListener('click', () => {
    resetSessionModal.classList.remove('active');
});

// Edit Exit Code Button
const editButtons = document.querySelectorAll('.edit-btn');
const editExitCodeModal = document.getElementById('editExitCodeModal');
const cancelEditBtn = document.getElementById('cancelEditBtn');
const exitCodeInput = document.getElementById('exitCodeInput');

editButtons.forEach(button => {
    button.addEventListener('click', () => {
        const studentLRN = button.getAttribute('data-student');
        const studentName = button.getAttribute('data-name');
        // We could use these values to customize the modal if needed

        editExitCodeModal.classList.add('active');
        exitCodeInput.focus();
    });
});

cancelEditBtn.addEventListener('click', () => {
    editExitCodeModal.classList.remove('active');
});

// Close modals when clicking on overlay
document.querySelectorAll('.modal-overlay').forEach(overlay => {
    overlay.addEventListener('click', (e) => {
        if (e.target === overlay) {
            overlay.classList.remove('active');
        }
    });
});