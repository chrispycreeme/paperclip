// js/checkbox-handler.js
console.log('--- checkbox-handler.js file started execution. ---');

document.addEventListener('DOMContentLoaded', () => {
    console.log('checkbox-handler.js script loaded and DOMContentLoaded event fired.');

    // Get all checkbox elements
    const checkboxes = document.querySelectorAll('.checkbox');
    console.log('Number of checkboxes found by checkbox-handler.js:', checkboxes.length);

    // Event listeners for 'Flagged As Cheater?' checkboxes
    checkboxes.forEach(checkbox => {
        console.log('Attaching click listener to checkbox:', checkbox);
        checkbox.addEventListener('click', (event) => {
            const studentLrn = event.currentTarget.dataset.studentLrn;
            // Toggle the current status
            let isFlagged = event.currentTarget.dataset.isFlagged === 'true';
            isFlagged = !isFlagged; // New status

            console.log('Checkbox Clicked:');
            console.log('  Student LRN:', studentLrn);
            console.log('  New Flag Status (boolean):', isFlagged);
            console.log('  New Flag Status (string sent to server):', isFlagged ? 'true' : 'false');

            // Update the UI immediately - No need to wait for server response
            updateUI(event.currentTarget, isFlagged);
            
            // Now update the server
            updateServerStatus(studentLrn, isFlagged, event.currentTarget);
        });
    });
    
    // Function to update the UI based on checkbox status
    function updateUI(checkbox, isFlagged) {
        // Update the checkbox appearance
        checkbox.dataset.isFlagged = isFlagged.toString();
        
        if (isFlagged) {
            checkbox.classList.add('checked');
            checkbox.innerHTML = `
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"
                    fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
                    stroke-linejoin="round">
                    <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
            `;
            
            // Update the row styling
            const row = checkbox.closest('tr');
            if (row) {
                row.querySelectorAll('td').forEach(cell => {
                    cell.classList.add('warning-student');
                });
            }
        } else {
            checkbox.classList.remove('checked');
            checkbox.innerHTML = '';
            
            // Update the row styling
            const row = checkbox.closest('tr');
            if (row) {
                row.querySelectorAll('td').forEach(cell => {
                    cell.classList.remove('warning-student');
                });
            }
        }
    }
    
    // Function to update the server with the checkbox status
    function updateServerStatus(studentLrn, isFlagged, checkbox) {
        // Store the initial state in case we need to revert
        const initialIsFlagged = checkbox.dataset.isFlagged === 'true';
        
        fetch('dashboard.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
                action: 'update_flag_status',
                lrn: studentLrn,
                is_flagged: isFlagged ? 'true' : 'false' // Send as string
            })
        })
        .then(response => {
            console.log('Fetch Response (raw):', response);
            if (!response.ok) {
                return response.text().then(text => {
                    throw new Error(`HTTP error! status: ${response.status}, body: ${text}`);
                });
            }
            
            // Try to parse as JSON, but handle non-JSON responses gracefully
            return response.text().then(text => {
                try {
                    return JSON.parse(text);
                } catch (e) {
                    // If not valid JSON, create a simple object with status based on HTTP response
                    return { status: response.ok ? 'success' : 'error', message: text };
                }
            });
        })
        .then(data => {
            console.log('Fetch Response (parsed):', data);
            if (data.status === 'success' || data.status === 'ok' || data === 'success') {
                console.log('Server update successful for LRN:', studentLrn, 'to flagged:', isFlagged);
                // UI is already updated, no need to do anything more
            } else if (data.message === 'Student not found or no change made.') {
                // This is likely just indicating no change was needed in the database
                // The UI is already updated correctly, so no need to revert
                console.log('No database change was needed, but UI is updated correctly');
            } else {
                console.error('Error updating flag status:', data.message || 'Unknown error');
                // Revert UI if the server reported an error
                console.log('Reverting UI due to server error.');
                updateUI(checkbox, initialIsFlagged);
                
                // Show error message to user - disable for now to prevent alert spam
                // alert('Error updating status. Please try again later.');
            }
        })
        .catch(error => {
            console.error('Network error or server issue:', error);
            // Revert UI if there's a network error
            console.log('Reverting UI due to network error.');
            updateUI(checkbox, initialIsFlagged);
            
            // Show error message to user
            alert('Network error. Please check your connection and try again.');
        });
    }
});