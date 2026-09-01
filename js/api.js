const API_URL = "http://localhost:3000/api/proxy?url=";
const REAL_API_URL = "https://app.logiciely.com/";

class ApiClient {
    static async get(endpoint, params = {}) {
        const user = Auth.getUser();
        if (!user) throw new Error("Non connecté");

        const queryStr = new URLSearchParams(params).toString();
        const separator = endpoint.includes("?") ? "&" : "?";
        const finalEndpoint = endpoint + (queryStr ? separator + queryStr : "");
        const targetUrl = encodeURIComponent(`${REAL_API_URL}${user.apiPath}${finalEndpoint}`);
        
        return await this.request(targetUrl, "GET");
    }

    static async post(endpoint, data = {}) {
        const user = Auth.getUser();
        if (!user) throw new Error("Non connecté");

        const targetUrl = encodeURIComponent(`${REAL_API_URL}${user.apiPath}${endpoint}`);
        return await this.request(targetUrl, "POST", data);
    }

    static async login(username, password) {
        const targetUrl = encodeURIComponent(`${REAL_API_URL}Login.php?Login=${username}&MotDePasse=${password}`);
        return await this.request(targetUrl, "GET");
    }

    static async request(targetUrl, method, data = null) {
        try {
            const options = {
                method: method,
                headers: {
                    "Content-Type": "application/json"
                }
            };

            if (data && method !== "GET") {
                options.body = JSON.stringify(data);
            }

            const response = await fetch(`${API_URL}${targetUrl}`, options);

            if (!response.ok) {
                if (response.status === 401) {
                    Auth.logout();
                }
                throw new Error(`Erreur réseau: ${response.status}`);
            }

            // Pour Login.php qui renvoie des donnأ©es avec UTF-8 BOM parfois
            const text = await response.text();
            try {
                return JSON.parse(text);
            } catch(e) {
                return text; // Retourner le texte brut si ce n est pas du json
            }
        } catch (error) {
            console.error("[API Error]", error);
            throw error;
        }
    }
}
window.ApiClient = ApiClient;

