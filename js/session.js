// Session management

const Session = {
    getUser: () => {
        const user = localStorage.getItem('user');
        return user ? JSON.parse(user) : null;
    },

    setUser: (userData) => {
        // Cache user data (ID, Nom, Status, Lien, etc)
        localStorage.setItem('user', JSON.stringify(userData));
    },

    clear: () => {
        localStorage.removeItem('user');
        // Clear other cached data here
        localStorage.removeItem('products_cache');
        localStorage.removeItem('dashboard_cache');
    },

    isAuthenticated: () => {
        const user = Session.getUser();
        return user !== null && user.Status === 'active';
    },

    getBaseUrl: () => {
        const user = Session.getUser();
        return user ? user.Lien : null;
    }
};
