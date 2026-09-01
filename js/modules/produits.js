window.ProduitsModule = {
    render: async function(container) {
        container.innerHTML = `
            <style>
                .product-actions { display: flex; justify-content: space-between; margin-bottom: 15px; }
                .search-box { flex: 1; margin-right: 15px; padding: 10px; border: 1px solid var(--border-color); border-radius: 5px; }
                .product-list { display: flex; flex-direction: column; gap: 10px; }
                .product-item {
                    background: var(--card-bg);
                    padding: 15px;
                    border-radius: 8px;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
                    cursor: pointer;
                }
                .product-info h4 { margin-bottom: 5px; }
                .product-price { font-weight: bold; color: var(--primary-color); }
            </style>
            
            <div class="product-actions">
                <input type="text" id="search-product" class="search-box" placeholder="Rechercher un produit ou scanner...">
                <button class="btn btn-primary" style="width:auto;"><i class="fas fa-plus"></i> Nouveau</button>
            </div>
            
            <div id="products-list" class="product-list">
                <div class="loader"><i class="fas fa-spinner fa-spin"></i> Chargement des produits...</div>
            </div>
        `;

        const productsList = document.getElementById('products-list');
        const searchInput = document.getElementById('search-product');

        // Check if coming from scanner
        const hashParams = new URLSearchParams(window.location.hash.split('?')[1]);
        if (hashParams.has('barcode')) {
            searchInput.value = hashParams.get('barcode');
        }

        try {
            // Load products from API
            const products = await ApiClient.get('liste_produit.php');
            
            if (Array.isArray(products)) {
                this.allProducts = products;
                this.renderList(productsList, products, searchInput.value);
                
                searchInput.addEventListener('input', (e) => {
                    this.renderList(productsList, this.allProducts, e.target.value);
                });
            } else {
                productsList.innerHTML = '<div class="error-msg">Format de données invalide</div>';
            }
        } catch(e) {
            productsList.innerHTML = '<div class="error-msg">Erreur de chargement: ' + e.message + '</div>';
        }
    },

    renderList: function(container, products, filterText = "") {
        container.innerHTML = "";
        
        let filtered = products;
        if (filterText) {
            const lowerFilter = filterText.toLowerCase();
            filtered = products.filter(p => 
                (p.Nom && p.Nom.toLowerCase().includes(lowerFilter)) || 
                (p.Reference && p.Reference.toLowerCase().includes(lowerFilter)) ||
                (p.CodeABarre && p.CodeABarre.includes(filterText))
            );
        }

        if (filtered.length === 0) {
            container.innerHTML = "<p>Aucun produit trouvé.</p>";
            return;
        }

        // Limit to 50 for performance
        const itemsToRender = filtered.slice(0, 50);

        itemsToRender.forEach(p => {
            const div = document.createElement("div");
            div.className = "product-item";
            div.innerHTML = `
                <div class="product-info">
                    <h4>${p.Nom || "Article commercial"}</h4>
                    <span style="font-size:0.8rem; color:var(--text-muted)">Réf: ${p.Reference || "-"} | Stock: ${p.Qte || 0}</span>
                </div>
                <div class="product-price">
                    ${parseFloat(p.PrixVenteDetait || 0).toFixed(2)} DA
                </div>
            `;
            div.onclick = () => alert("Détails de " + p.Nom);
            container.appendChild(div);
        });
    }
};
