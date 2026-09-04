// Products logic

const Products = {
    render: async (container) => {
        container.innerHTML = `
            <div class="card">
                <div class="card-header">
                    <h3>Liste des Produits</h3>
                    <button class="btn btn-primary" onclick="Products.showAddForm()"><i class="fas fa-plus"></i> Nouveau Produit</button>
                </div>
                <div class="form-group">
                    <input type="text" id="search-product" placeholder="Rechercher un produit (Nom, Référence, Code-barres)..." onkeyup="Products.filter()">
                </div>
                <div class="table-responsive">
                    <table id="products-table">
                        <thead>
                            <tr>
                                <th>Référence</th>
                                <th>Nom du produit</th>
                                <th>Quantité</th>
                                <th>Prix Achat</th>
                                <th>Prix Vente</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody id="products-list">
                            <tr><td colspan="6" style="text-align: center;">Chargement...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        `;
        
        Products.loadData();
    },
    
    loadData: async () => {
        try {
            const data = await API.get('liste_stock.php');
            Products.allProducts = Array.isArray(data) ? data : (data.data || []);
            Products.renderList(Products.allProducts);
        } catch (error) {
            document.getElementById('products-list').innerHTML = `<tr><td colspan="6" class="text-danger text-center">Erreur: ${error.message}</td></tr>`;
        }
    },
    
    renderList: (products) => {
        const tbody = document.getElementById('products-list');
        if (!tbody) return;
        
        if (products.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" style="text-align: center;">Aucun produit trouvé</td></tr>';
            return;
        }
        
        tbody.innerHTML = products.map(p => `
            <tr>
                <td>${p.Reference || '-'}</td>
                <td><strong>${p.Libelle}</strong></td>
                <td><span class="badge ${p.Qte <= 0 ? 'text-danger' : ''}">${p.Qte || 0}</span></td>
                <td>${Utils.formatCurrency(p.PrixAchat)}</td>
                <td>${Utils.formatCurrency(p.PrixVente)}</td>
                <td>
                    <button class="btn-icon text-info" onclick="Products.edit(${p.IDProduit})"><i class="fas fa-edit"></i></button>
                </td>
            </tr>
        `).join('');
    },
    
    filter: () => {
        const query = document.getElementById('search-product').value.toLowerCase();
        if (!Products.allProducts) return;
        
        const filtered = Products.allProducts.filter(p => 
            (p.Libelle && p.Libelle.toLowerCase().includes(query)) || 
            (p.Reference && p.Reference.toLowerCase().includes(query))
        );
        Products.renderList(filtered);
    },
    
    showAddForm: () => {
        // Form logic here
        alert('Ajout de produit non implémenté dans cette démo');
    },
    
    edit: (id) => {
        alert('Modification de produit ' + id);
    }
};
