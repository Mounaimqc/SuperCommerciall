window.VentesModule = {
    render: async function(container) {
        container.innerHTML = `
            <style>
                .ventes-header { display: flex; justify-content: space-between; margin-bottom: 20px; align-items: center; }
                .ventes-list { display: flex; flex-direction: column; gap: 15px; }
                .vente-card {
                    background: var(--card-bg);
                    padding: 15px;
                    border-radius: 8px;
                    border-left: 4px solid var(--primary-color);
                    box-shadow: 0 2px 5px rgba(0,0,0,0.05);
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    cursor: pointer;
                }
                .vente-info h4 { margin-bottom: 5px; color: var(--text-color); }
                .vente-meta { font-size: 0.85rem; color: var(--text-muted); }
                .vente-amount { font-weight: bold; font-size: 1.1rem; color: var(--primary-dark); }
            </style>
            
            <div class="ventes-header">
                <h2>Liste des Ventes</h2>
                <button class="btn btn-primary" onclick="window.location.hash='nouvelle-vente'">
                    <i class="fas fa-plus"></i> Nouvelle Vente
                </button>
            </div>
            
            <div id="ventes-container" class="ventes-list">
                <div class="loader"><i class="fas fa-spinner fa-spin fa-2x"></i></div>
            </div>
        `;

        const ventesContainer = document.getElementById("ventes-container");

        try {
            // Appeler l'API SAGE via notre proxy
            const ventes = await ApiClient.get('liste_document.php', { Type: 6 });
            
            if (Array.isArray(ventes)) {
                if (ventes.length === 0) {
                    ventesContainer.innerHTML = "<p>Aucune vente trouvée.</p>";
                    return;
                }
                
                ventesContainer.innerHTML = "";
                // Afficher les 50 dernières ventes
                ventes.slice(0, 50).forEach(v => {
                    const card = document.createElement("div");
                    card.className = "vente-card";
                    card.innerHTML = `
                        <div class="vente-info">
                            <h4>${v.Nom || 'Client Inconnu'}</h4>
                            <div class="vente-meta">
                                <i class="far fa-calendar-alt"></i> ${v.Date} à ${v.Heure} 
                                | Réf: ${v.NumeroDocument || v.ID}
                            </div>
                        </div>
                        <div class="vente-amount">
                            ${parseFloat(v.Total || 0).toFixed(2)} DA
                        </div>
                    `;
                    card.onclick = () => alert("Détails de la vente N° " + v.ID + " en cours de développement");
                    ventesContainer.appendChild(card);
                });
            } else {
                ventesContainer.innerHTML = '<div class="error-msg">Format de données invalide</div>';
            }
        } catch(error) {
            ventesContainer.innerHTML = `<div class="error-msg">Erreur de chargement: ${error.message}</div>`;
        }
    }
};
