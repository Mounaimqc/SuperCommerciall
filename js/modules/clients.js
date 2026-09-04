window.ClientsModule = {
    render: async function(container) {
        container.innerHTML = `
            <style>
                .clients-header { display: flex; justify-content: space-between; margin-bottom: 20px; align-items: center; }
                .search-box { flex: 1; padding: 10px; border: 1px solid var(--border-color); border-radius: 5px; margin-right:15px; }
                .clients-list { display: flex; flex-direction: column; gap: 10px; }
                .client-card {
                    background: var(--card-bg);
                    padding: 15px;
                    border-radius: 8px;
                    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    cursor: pointer;
                }
                .client-info h4 { margin-bottom: 5px; color: var(--primary-color); }
                .client-meta { font-size: 0.85rem; color: var(--text-muted); }
                .client-solde { font-weight: bold; }
                .solde-positif { color: var(--danger-color); } /* Dettes */
                .solde-zero { color: var(--success-color); }
            </style>
            
            <div class="clients-header">
                <input type="text" id="search-client" class="search-box" placeholder="Rechercher un client...">
                <button class="btn btn-primary" style="width:auto;"><i class="fas fa-plus"></i></button>
            </div>
            
            <div id="clients-container" class="clients-list">
                <div class="loader"><i class="fas fa-spinner fa-spin fa-2x"></i></div>
            </div>
        `;

        const clientsContainer = document.getElementById("clients-container");
        const searchInput = document.getElementById("search-client");

        try {
            const clients = await ApiClient.get('liste_clients.php');
            
            if (Array.isArray(clients)) {
                this.allClients = clients;
                this.renderList(clientsContainer, clients, "");
                
                searchInput.addEventListener('input', (e) => {
                    this.renderList(clientsContainer, this.allClients, e.target.value);
                });
            } else {
                clientsContainer.innerHTML = '<div class="error-msg">Format de données invalide</div>';
            }
        } catch(error) {
            clientsContainer.innerHTML = `<div class="error-msg">Erreur de chargement: ${error.message}</div>`;
        }
    },

    renderList: function(container, clients, filterText = "") {
        container.innerHTML = "";
        
        let filtered = clients;
        if (filterText) {
            const lowerFilter = filterText.toLowerCase();
            filtered = clients.filter(c => 
                (c.Nom && c.Nom.toLowerCase().includes(lowerFilter)) || 
                (c.Telephone && c.Telephone.includes(filterText))
            );
        }

        if (filtered.length === 0) {
            container.innerHTML = "<p>Aucun client trouvé.</p>";
            return;
        }

        filtered.slice(0, 50).forEach(c => {
            const solde = parseFloat(c.Solde || 0);
            const soldeClass = solde > 0 ? "solde-positif" : "solde-zero";
            
            const card = document.createElement("div");
            card.className = "client-card";
            card.innerHTML = `
                <div class="client-info">
                    <h4><i class="fas fa-user"></i> ${c.Nom || 'Sans Nom'}</h4>
                    <div class="client-meta">
                        <i class="fas fa-phone"></i> ${c.Telephone || '-'}
                    </div>
                </div>
                <div class="client-solde ${soldeClass}">
                    ${solde.toFixed(2)} DA
                </div>
            `;
            card.onclick = () => {
                // Rediriger vers la situation du client
                window.location.hash = `situation?id=${c.ID}&type=1`;
            };
            container.appendChild(card);
        });
    }
};
