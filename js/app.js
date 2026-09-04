// Main Application logic

const App = {
    init: () => {
        // Initialize Auth module
        Auth.init();
        
        // Check session
        if (Session.isAuthenticated()) {
            App.showMainView();
        } else {
            App.showAuthView();
        }
    },

    showAuthView: () => {
        document.getElementById('auth-view').classList.remove('hidden');
        document.getElementById('main-view').classList.add('hidden');
    },

    showMainView: () => {
        document.getElementById('auth-view').classList.add('hidden');
        document.getElementById('main-view').classList.remove('hidden');
        
        // Update user info
        const user = Session.getUser();
        if (user) {
            document.getElementById('user-name').textContent = user.Nom || 'Utilisateur';
            // Setup base URL logic if needed
        }
        
        // Initialize Navigation
        Navigation.init();
    }
};

// Start the app when DOM is ready
document.addEventListener('DOMContentLoaded', App.init);
