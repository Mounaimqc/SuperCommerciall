// Navigation logic

const Navigation = {
    init: () => {
        // Handle hash changes
        window.addEventListener('hashchange', Navigation.handleHashChange);
        
        // Mobile menu toggle
        const menuToggle = document.getElementById('btn-menu-toggle');
        if (menuToggle) {
            menuToggle.addEventListener('click', () => {
                const sidebar = document.querySelector('.sidebar');
                sidebar.style.display = sidebar.style.display === 'flex' ? 'none' : 'flex';
                sidebar.style.position = 'absolute';
                sidebar.style.height = '100%';
                sidebar.style.zIndex = '1000';
            });
        }
        
        // Initial route
        if (window.location.hash) {
            Navigation.handleHashChange();
        } else {
            window.location.hash = '#dashboard';
        }
    },

    handleHashChange: () => {
        const hash = window.location.hash || '#dashboard';
        const page = hash.replace('#', '');
        
        // Update title
        const pageTitle = document.getElementById('page-title');
        if (pageTitle) {
            pageTitle.textContent = page.charAt(0).toUpperCase() + page.slice(1);
        }
        
        // Update active states
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
            if (item.getAttribute('href') === hash) {
                item.classList.add('active');
            }
        });
        
        // Close mobile sidebar if open
        if (window.innerWidth <= 768) {
            const sidebar = document.querySelector('.sidebar');
            if (sidebar) sidebar.style.display = 'none';
        }
        
        // Load content
        Navigation.loadPage(page);
    },

    loadPage: (page) => {
        const container = document.getElementById('page-container');
        container.innerHTML = ''; // Clear current content
        
        // Map pages to their init functions
        const routes = {
            'dashboard': Dashboard.render,
            'produits': Products.render,
            'ventes': Ventes.render,
            'achats': Achats.render,
            'clients': Clients.render,
            'fournisseurs': Fournisseurs.render,
            'versements': Versements.render,
            'situation': Situation.render,
            'charges': Charges.render,
            'caisse': Caisse.render,
            'statistiques': Statistiques.render,
            'scanner': Scanner.render
        };
        
        if (routes[page]) {
            routes[page](container);
        } else {
            container.innerHTML = '<div class="card"><h2>Page introuvable</h2></div>';
        }
    }
};
