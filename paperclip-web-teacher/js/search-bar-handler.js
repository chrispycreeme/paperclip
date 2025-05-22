document.addEventListener('DOMContentLoaded', function() {
    const searchInput = document.getElementById('studentSearch');
    const clearButton = document.getElementById('clearSearch');
    const searchStats = document.getElementById('searchStats');
    const tableRows = document.querySelectorAll('.student-table tbody tr');
    const totalStudents = tableRows.length;

    function updateSearchStats(visibleCount) {
        if (visibleCount === totalStudents) {
            searchStats.textContent = `Showing all ${totalStudents} students`;
        } else {
            searchStats.textContent = `Showing ${visibleCount} of ${totalStudents} students`;
        }
    }

    function performSearch() {
        const searchTerm = searchInput.value.toLowerCase().trim();
        let visibleCount = 0;

        if (searchTerm === '') {
            clearButton.classList.remove('visible');
        } else {
            clearButton.classList.add('visible');
        }

        tableRows.forEach(row => {
            const lrn = row.querySelector('[data-label="Student LRN"]')?.textContent.toLowerCase() || '';
            const name = row.querySelector('[data-label="Student Name"]')?.textContent.toLowerCase() || '';
            
            // For desktop view, check regular table cells
            const lrnCell = row.cells?.[0]?.textContent.toLowerCase() || '';
            const nameCell = row.cells?.[1]?.textContent.toLowerCase() || '';

            const matches = lrn.includes(searchTerm) || 
                          name.includes(searchTerm) || 
                          lrnCell.includes(searchTerm) || 
                          nameCell.includes(searchTerm);

            if (matches) {
                row.style.display = '';
                visibleCount++;
            } else {
                row.style.display = 'none';
            }
        });

        updateSearchStats(visibleCount);
    }

    function clearSearch() {
        searchInput.value = '';
        clearButton.classList.remove('visible');
        tableRows.forEach(row => {
            row.style.display = '';
        });
        updateSearchStats(totalStudents);
        searchInput.focus();
    }

    // Event listeners
    searchInput.addEventListener('input', performSearch);
    searchInput.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            clearSearch();
        }
    });
    clearButton.addEventListener('click', clearSearch);

    // Initialize stats
    updateSearchStats(totalStudents);
});