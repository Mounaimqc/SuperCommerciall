// Utility functions for UI and common tasks

const Utils = {
    showLoading: (text = 'Chargement...') => {
        const overlay = document.getElementById('loading-overlay');
        const loadingText = document.getElementById('loading-text');
        if (loadingText) loadingText.textContent = text;
        if (overlay) overlay.classList.remove('hidden');
    },

    hideLoading: () => {
        const overlay = document.getElementById('loading-overlay');
        if (overlay) overlay.classList.add('hidden');
    },

    formatCurrency: (amount) => {
        if (!amount) return '0.00 DA';
        return parseFloat(amount).toLocaleString('fr-FR', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }) + ' DA';
    },

    formatDate: (dateString) => {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString('fr-FR');
    },
    
    // Generic error handler
    showError: (message) => {
        alert('Erreur: ' + message); // Could be replaced by a nicer toast
    },

    createElement: (tag, className, content) => {
        const el = document.createElement(tag);
        if (className) el.className = className;
        if (content) el.innerHTML = content;
        return el;
    }
};
