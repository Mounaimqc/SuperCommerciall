document.addEventListener('DOMContentLoaded', () => {
    const loginView = document.getElementById('login-view');
    const mainView = document.getElementById('main-view');
    const loginForm = document.getElementById('login-form');
    const loginError = document.getElementById('login-error');
    const logoutBtn = document.getElementById('logout-btn');
    const userInfo = document.getElementById('user-info');
    const navItems = document.querySelectorAll('.nav-item, .bnav-item:not(.scanner-wrapper)');
    const routeContent = document.getElementById('route-content');
    const pageTitle = document.getElementById('page-title');

    function init() {
        const user = Auth.getUser();
        if (user) {
            if (user.status !== 'active') {
                showLoginError('Ce compte n est pas actif. Expire le: ' + (user.dateFin || 'inconnu'));
                Auth.logout();
                return;
            }
            showMainView(user);
        } else {
            showLoginView();
        }
    }

    function showLoginView() {
        loginView.classList.remove('hidden');
        mainView.classList.add('hidden');
    }

    function showMainView(user) {
        loginView.classList.add('hidden');
        mainView.classList.remove('hidden');
        userInfo.innerHTML = '<p>Connecté en tant que <strong>' + user.nom + '</strong></p><p class="date-fin">Valide jusqu\'au ' + user.dateFin + '</p>';
        const hash = window.location.hash.replace('#', '') || 'dashboard';
        loadRoute(hash);
    }

    function showLoginError(msg) {
        loginError.textContent = msg;
        loginError.style.display = 'block';
    }

    async function loadRoute(route) {
        window.location.hash = route;
        navItems.forEach(item => {
            item.classList.remove('active');
            if (item.dataset.route === route) {
                item.classList.add('active');
                pageTitle.textContent = item.textContent.trim();
            }
        });
        routeContent.innerHTML = '<div class="loader"><i class="fas fa-spinner fa-spin fa-3x"></i></div>';
        try {
            const moduleName = route.charAt(0).toUpperCase() + route.slice(1) + "Module";
            if (window[moduleName]) {
                await window[moduleName].render(routeContent);
            } else {
                routeContent.innerHTML = '<h2>Module ' + route + ' en construction</h2><p>Cette section est en cours de développement.</p>';
            }
        } catch (e) {
            routeContent.innerHTML = '<div class="error-msg">Erreur de chargement de la page: ' + e.message + '</div>';
        }
    }

    window.addEventListener('hashchange', () => {
        const hash = window.location.hash.replace('#', '') || 'dashboard';
        loadRoute(hash);
    });

    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const userField = document.getElementById('login-username').value;
        const passField = document.getElementById('login-password').value;
        const submitBtn = document.getElementById('login-btn');
        loginError.style.display = 'none';
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Connexion...';

        try {
            const data = await ApiClient.login(userField, passField);
            if (Array.isArray(data) && data.length > 0) {
                const userData = data[0];
                if (userData.Status === 'active') {
                    Auth.setUser(userData);
                    init();
                } else {
                    showLoginError('Ce compte n est plus actif. (Expiration: ' + userData.DateFin + ')');
                }
            } else {
                showLoginError('Identifiants incorrects.');
            }
        } catch (error) {
            showLoginError('Impossible de joindre le serveur. (' + error.message + ')');
        } finally {
            submitBtn.disabled = false;
            submitBtn.innerHTML = 'Se connecter';
        }
    });

    logoutBtn.addEventListener('click', () => {
        Auth.logout();
    });

    init();
});
