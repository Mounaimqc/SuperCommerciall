// Dashboard logic

const Dashboard = {
    render: async (container) => {
        container.innerHTML = `
            <div class="dashboard-grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem; margin-bottom: 2rem;">
                <div class="card" style="border-left: 4px solid var(--primary-color);">
                    <h3 style="color: var(--text-secondary); font-size: 0.875rem; margin-bottom: 0.5rem;">Caisse du jour</h3>
                    <div id="dash-caisse" style="font-size: 1.5rem; font-weight: 700;">-- DA</div>
                </div>
                <div class="card" style="border-left: 4px solid var(--success-color);">
                    <h3 style="color: var(--text-secondary); font-size: 0.875rem; margin-bottom: 0.5rem;">Ventes du jour</h3>
                    <div id="dash-ventes" style="font-size: 1.5rem; font-weight: 700;">-- DA</div>
                </div>
                <div class="card" style="border-left: 4px solid var(--danger-color);">
                    <h3 style="color: var(--text-secondary); font-size: 0.875rem; margin-bottom: 0.5rem;">Achats du jour</h3>
                    <div id="dash-achats" style="font-size: 1.5rem; font-weight: 700;">-- DA</div>
                </div>
                <div class="card" style="border-left: 4px solid var(--warning-color);">
                    <h3 style="color: var(--text-secondary); font-size: 0.875rem; margin-bottom: 0.5rem;">Charges du jour</h3>
                    <div id="dash-charges" style="font-size: 1.5rem; font-weight: 700;">-- DA</div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <h3>Actions rapides</h3>
                </div>
                <div style="display: flex; gap: 1rem; flex-wrap: wrap;">
                    <button class="btn btn-primary" onclick="window.location.hash='#ventes'"><i class="fas fa-plus"></i> Nouvelle Vente</button>
                    <button class="btn btn-primary" style="background-color: var(--success-color);" onclick="window.location.hash='#achats'"><i class="fas fa-plus"></i> Nouvel Achat</button>
                    <button class="btn btn-primary" style="background-color: var(--info-color);" onclick="window.location.hash='#produits'"><i class="fas fa-box"></i> Stock</button>
                </div>
            </div>
        `;
        
        Dashboard.loadData();
    },
    
    loadData: async () => {
        try {
            // Placeholder for API call
            // const stats = await API.get('statistique.php?DateDebut=...&DateFin=...');
            // Populate stats
        } catch (error) {
            console.error(error);
        }
    }
};
