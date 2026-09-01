window.ScannerModule = {
    html5QrcodeScanner: null,

    init: function() {
        const fabScanner = document.getElementById("fab-scanner");
        const scannerOverlay = document.getElementById("scanner-overlay");
        const closeScanner = document.getElementById("close-scanner");

        fabScanner.addEventListener("click", () => {
            scannerOverlay.classList.remove("hidden");
            this.startScanner();
        });

        closeScanner.addEventListener("click", () => {
            scannerOverlay.classList.add("hidden");
            this.stopScanner();
        });
    },

    startScanner: function() {
        if (!this.html5QrcodeScanner) {
            this.html5QrcodeScanner = new Html5Qrcode("reader");
        }
        
        const config = { fps: 10, qrbox: { width: 250, height: 250 } };
        
        this.html5QrcodeScanner.start(
            { facingMode: "environment" },
            config,
            (decodedText, decodedResult) => {
                // Success callback
                console.log(`Code scanné = ${decodedText}`);
                this.stopScanner();
                document.getElementById("scanner-overlay").classList.add("hidden");
                
                // Rediriger vers la page du produit
                window.location.hash = `produits?barcode=${decodedText}`;
            },
            (errorMessage) => {
                // Ignore parse errors (too noisy)
            }
        ).catch((err) => {
            alert("Erreur lors de l'ouverture de la caméra. Assurez-vous d'être en HTTPS. " + err);
        });
    },

    stopScanner: function() {
        if (this.html5QrcodeScanner && this.html5QrcodeScanner.isScanning) {
            this.html5QrcodeScanner.stop().then((ignore) => {
                this.html5QrcodeScanner.clear();
            }).catch((err) => {
                console.error("Stop failed: ", err);
            });
        }
    }
};

// Auto-init Scanner when loaded
document.addEventListener("DOMContentLoaded", () => {
    // Wait slightly to ensure UI is ready
    setTimeout(() => {
        if(window.ScannerModule) window.ScannerModule.init();
    }, 500);
});
