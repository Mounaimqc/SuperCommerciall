class Auth {
    static getUser() {
        const userStr = localStorage.getItem("sc_user");
        if (!userStr) return null;
        const user = JSON.parse(userStr);
        // Check if expired
        if (user.expireAt && new Date(user.expireAt) < new Date()) {
            this.logout();
            return null;
        }
        return user;
    }

    static setUser(userData) {
        if (!userData || !userData.Lien) return false;
        
        // Nettoyer les donnأ©es
        let apiPath = userData.Lien.trim();
        if (apiPath.endsWith("/")) {
            apiPath = apiPath.slice(0, -1);
        }
        // Retirer le nom de domaine s il y est
        apiPath = apiPath.replace("https://app.logiciely.com/", "").replace("http://app.logiciely.com/", "");
        if (!apiPath.endsWith("/")) apiPath += "/";

        const user = {
            id: userData.ID,
            nom: userData.Nom,
            status: userData.Status,
            apiPath: apiPath,
            dateFin: userData.DateFin,
            // set expiration in 24h
            expireAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
        };

        localStorage.setItem("sc_user", JSON.stringify(user));
        return true;
    }

    static logout() {
        localStorage.removeItem("sc_user");
        window.location.reload();
    }
}
window.Auth = Auth;

