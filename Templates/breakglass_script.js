// Tab functionality
function openTab(evt, tabName) {
    // Declare variables
    var i, tabcontent, tablinks;
    
    // Get all elements with class="tabcontent" and hide them
    tabcontent = document.getElementsByClassName("tabcontent");
    for (i = 0; i < tabcontent.length; i++) {
        tabcontent[i].style.display = "none";
    }
    
    // Get all elements with class="tablinks" and remove the class "active"
    tablinks = document.getElementsByClassName("tablinks");
    for (i = 0; i < tablinks.length; i++) {
        tablinks[i].className = tablinks[i].className.replace(" active", "");
    }
    
    // Show the current tab, and add an "active" class to the button that opened the tab
    document.getElementById(tabName).style.display = "block";
    evt.currentTarget.className += " active";
}

// Dark mode functionality
function setupDarkMode() {
    const darkModeToggle = document.getElementById('darkModeToggle');
    
    // Check for saved theme preference or respect OS theme preference
    const savedTheme = localStorage.getItem('breakGlassTheme');
    const prefersDarkScheme = window.matchMedia('(prefers-color-scheme: dark)');
    
    if (savedTheme === 'dark' || (!savedTheme && prefersDarkScheme.matches)) {
        document.documentElement.setAttribute('data-theme', 'dark');
        darkModeToggle.checked = true;
    }
    
    // Add event listener for theme toggle
    darkModeToggle.addEventListener('change', function() {
        if (this.checked) {
            document.documentElement.setAttribute('data-theme', 'dark');
            localStorage.setItem('breakGlassTheme', 'dark');
        } else {
            document.documentElement.setAttribute('data-theme', 'light');
            localStorage.setItem('breakGlassTheme', 'light');
        }
    });
}

// CSV Export functionality
function exportToCSV() {
    // Create array to store all policy data
    let csvData = [];
    
    // Add header row
    csvData.push(['Break Glass Account', 'Policy Name', 'Policy ID', 'State', 'Description']);
    
    // Get all tab content divs
    const tabContents = document.getElementsByClassName('tabcontent');
    
    // Loop through each tab (each break glass account)
    for (let i = 0; i < tabContents.length; i++) {
        const tabContent = tabContents[i];
        const accountNameElement = tabContent.querySelector('.account-info h3');
        
        if (!accountNameElement) continue;
        
        const accountName = accountNameElement.textContent.replace('Account: ', '');
        
        // Get all policy cards for this account
        const policyCards = tabContent.querySelectorAll('.policy-card');
        
        // If there are no policy cards, add a row indicating no issues
        if (policyCards.length === 0) {
            csvData.push([accountName, 'No Issues', '', '', 'Properly excluded from all policies']);
            continue;
        }
        
        // Loop through each policy card
        for (let j = 0; j < policyCards.length; j++) {
            const card = policyCards[j];
            const policyName = card.querySelector('h3').textContent;
            const policyId = card.querySelector('.policy-id').textContent.replace('ID: ', '');
            const policyState = card.querySelector('.policy-status').textContent;
            let policyDescription = '';
            
            // Get description if it exists
            const descriptionElement = card.querySelector('p');
            if (descriptionElement) {
                policyDescription = descriptionElement.textContent;
                if (policyDescription === 'No description') {
                    policyDescription = '';
                }
            }
            
            // Add to CSV data
            csvData.push([accountName, policyName, policyId, policyState, policyDescription]);
        }
    }
    
    // Convert array to CSV string
    let csvContent = csvData.map(row => row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(',')).join('\n');
    
    // Create download link
    const encodedUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', 'BreakGlass_Policy_Exclusions.csv');
    document.body.appendChild(link);
    
    // Trigger download
    link.click();
    
    // Clean up
    document.body.removeChild(link);
}

// Initialize everything when the page loads
document.addEventListener('DOMContentLoaded', function() {
    // Set up tab functionality - open the first tab by default
    if (document.getElementsByClassName("tablinks").length > 0) {
        document.getElementsByClassName("tablinks")[0].click();
    }
    
    // Set up dark mode toggle
    setupDarkMode();
    
    // Set up CSV export button
    const exportButton = document.getElementById('exportCSV');
    if (exportButton) {
        exportButton.addEventListener('click', exportToCSV);
    }
});