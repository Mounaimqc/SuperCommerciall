// Auth logic

const Auth = {
    init: () => {
        const loginForm = document.getElementById('login-form');
        const logoutBtn = document.getElementById('btn-logout');
        
        if (loginForm) {
            loginForm.addEventListener('submit', Auth.handleLogin);
        }
        
        if (logoutBtn) {
            logoutBtn.addEventListener('click', Auth.handleLogout);
        }
    },

    handleLogin: async (e) => {
        e.preventDefault();
        const usernameInput = document.getElementById('login-username').value;
        const passwordInput = document.getElementById('login-password').value;
        const errorDiv = document.getElementById('login-error');
        
        errorDiv.classList.add('hidden');
        Utils.showLoading('Connexion...');
        
        try {
            const result = await API.login(usernameInput, passwordInput);
            
            if (result.success && result.Status === 'active') {
                Session.setUser(result);
                App.showMainView();
            } else {
                errorDiv.textContent = result.message || 'Identifiants incorrects ou compte inactif.';
                errorDiv.classList.remove('hidden');
            }
        } catch (error) {
            errorDiv.textContent = error.message;
            errorDiv.classList.remove('hidden');
        } finally {
            Utils.hideLoading();
        }
    },

    handleLogout: () => {
        if (confirm('Voulez-vous vraiment vous déconnecter ?')) {
            Session.clear();
            App.showAuthView();
        }
    }
};
