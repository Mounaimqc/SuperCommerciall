// API interaction

const PROXY_URL = '/api/proxy?url=';
const LOGIN_URL = 'https://app.logiciely.com/Login.php';

const API = {
    // Perform authentication
    login: async (username, password) => {
        try {
            // Encode parameters manually to match PHP expectations if needed, but proxy passes them correctly
            const targetUrl = `${LOGIN_URL}?Login=${encodeURIComponent(username)}&MotDePasse=${encodeURIComponent(password)}`;
            const response = await fetch(PROXY_URL + encodeURIComponent(targetUrl), {
                method: 'GET',
                headers: {
                    'Accept': 'application/json'
                }
            });
            
            if (!response.ok) throw new Error('Erreur de connexion au serveur');
            
            const data = await response.json();
            return data;
        } catch (error) {
            console.error('Login error:', error);
            throw new Error('Connexion impossible');
        }
    },

    // Generic fetch through proxy
    get: async (endpoint) => {
        const baseUrl = Session.getBaseUrl();
        if (!baseUrl) throw new Error('Session expirée');
        
        try {
            const targetUrl = `${baseUrl}${endpoint}`;
            const response = await fetch(PROXY_URL + encodeURIComponent(targetUrl), {
                method: 'GET',
                headers: {
                    'Accept': 'application/json, text/plain, */*'
                }
            });
            
            if (!response.ok) throw new Error(`HTTP error ${response.status}`);
            
            const contentType = response.headers.get('content-type');
            if (contentType && contentType.includes('application/json')) {
                return await response.json();
            } else {
                return await response.text(); // Some endpoints return plain text code
            }
        } catch (error) {
            console.error('API GET error:', error);
            throw new Error('Serveur indisponible');
        }
    }
};
