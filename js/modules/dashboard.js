window.DashboardModule = {
    render: async function(container) {
        container.innerHTML = `
            <style>
                .dashboard-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 15px;
                    margin-bottom: 20px;
                }
                .dash-card {
                    background: var(--card-bg);
                    padding: 20px;
                    border-radius: 10px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.05);
                    display: flex;
                    align-items: center;
                    gap: 15px;
                    border-left: 4px solid var(--primary-color);
                }
                .dash-card.green { border-left-color: var(--success-color); }
                .dash-card.red { border-left-color: var(--danger-color); }
                .dash-card i { font-size: 2rem; color: var(--text-muted); opacity: 0.5; }
                .dash-card-info h3 { font-size: 0.9rem; color: var(--text-muted); margin-bottom: 5px; }
                .dash-card-info p { font-size: 1.5rem; font-weight: bold; }
            </style>
            
            <div class="dashboard-grid">
                <div class="dash-card">
                    <i class="fas fa-shopping-cart"></i>
                    <div class="dash-card-info">
                        <h3>Ventes du jour</h3>
                        <p id="dash-ventes">...</p>
                    </div>
                </div>
                <div class="dash-card green">
                    <i class="fas fa-cash-register"></i>
                    <div class="dash-card-info">
                        <h3>Recettes</h3>
                        <p id="dash-recettes">...</p>
                    </div>
                </div>
                <div class="dash-card red">
                    <i class="fas fa-file-invoice-dollar"></i>
                    <div class="dash-card-info">
                        <h3>Charges</h3>
                        <p id="dash-charges">...</p>
                    </div>
                </div>
            </div>
            
            <div style="background:var(--card-bg); padding:20px; border-radius:10px; box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                <h3>Bienvenue sur Super Commercial Web</h3>
                <p style="margin-top:10px; color:var(--text-muted)">Sélectionnez une option dans le menu pour commencer.</p>
            </div>
        `;

        try {
            // Load real stats if API allows
            const stats = await ApiClient.get('statistique.php');
            // Assuming the API returns total sales etc, we populate it
            // This needs to match the actual SAGE API structure
            console.log("Stats reçues:", stats);
            // document.getElementById('dash-ventes').textContent = stats.Ventes + " DA";
        } catch(e) {
            console.warn("Impossible de charger les statistiques");
        }
    }
};
