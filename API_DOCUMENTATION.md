# Documentation des API (Projet Flutter)

Ce document contient l'inventaire exhaustif de toutes les API utilisées dans l'application Flutter (SAGE / Commercial App).

---

## 1. Authentication & Base URL
- **Nom** : Login API
- **URL** : `https://app.logiciely.com/Login.php`
- **Endpoint** : `Login.php`
- **GET ou POST** : GET
- **Paramètres** : `Login`, `MotDePasse`
- **Exemple de requête** : `Login.php?Login=admin&MotDePasse=1234`
- **Réponse attendue** : Objet JSON contenant `success`, `Status`, `Lien` (qui sera la `baseUrl`), `ID`, `Nom`
- **Type utilisé** : Map<String, dynamic>
- **Écran qui l'utilise** : Écran de connexion (Login Screen)
- **Rôle de l'API** : Authentifier l'utilisateur et récupérer l'URL de base (baseUrl) dynamique du client.

## 2. Caisse (Cash Register)
- **Nom** : Load Operations Caisse
- **URL** : `{baseUrl}caisse.php`
- **Endpoint** : `caisse.php`
- **GET ou POST** : GET
- **Paramètres** : `DateDebut`, `DateFin`
- **Exemple de requête** : `caisse.php?DateDebut=2023-01-01&DateFin=2023-12-31`
- **Réponse attendue** : Tableau JSON des opérations de caisse
- **Type utilisé** : `CaisseModel`
- **Écran qui l'utilise** : Écran de la Caisse (Caisse Screen)
- **Rôle de l'API** : Charger les opérations de caisse entre deux dates.

## 3. Charges (Expenses) - Liste
- **Nom** : Fetch Charges
- **URL** : `{baseUrl}Liste_charge.php`
- **Endpoint** : `Liste_charge.php`
- **GET ou POST** : GET
- **Paramètres** : `DateDebut`, `DateFin`
- **Exemple de requête** : `Liste_charge.php?DateDebut=2023-01-01&DateFin=2023-12-31`
- **Réponse attendue** : Tableau JSON des charges
- **Type utilisé** : `ChargeModel`
- **Écran qui l'utilise** : Liste des Charges
- **Rôle de l'API** : Récupérer la liste des dépenses/charges sur une période.

## 4. Charges (Expenses) - Ajout
- **Nom** : Insert Charge
- **URL** : `{baseUrl}insert_charge.php`
- **Endpoint** : `insert_charge.php`
- **GET ou POST** : GET
- **Paramètres** : `IDcharge`, `Date`, `Heure`, `Montant`, `ModeReglement`, `AjoutePar`, `ModifiePar`, `Type`, `Paye`, `Observation`, `Motif`
- **Exemple de requête** : `insert_charge.php?IDcharge=0&Date=2023-10-10&Montant=500...`
- **Réponse attendue** : Code HTTP 200 OK
- **Type utilisé** : `ChargeModel`
- **Écran qui l'utilise** : Écran d'ajout de charge
- **Rôle de l'API** : Ajouter une nouvelle charge au système.

## 5. Tiers - Ajout Client
- **Nom** : Insert Client
- **URL** : `{baseUrl}Insert_tiers.php`
- **Endpoint** : `Insert_tiers.php`
- **GET ou POST** : GET
- **Paramètres** : `IDTiers`, `Nom`, `Adresse`, `Telephone`, `NIS`, `NAI`, `NIF`, `Solde`, `Type` (fixé à 1), `AjoutePar`, `NRC`, `RIB`, `GestionDeFidelite`, `Note`, `Facebook`, `AncienSolde`
- **Exemple de requête** : `Insert_tiers.php?IDTiers=0&Nom=John&Type=1...`
- **Réponse attendue** : Code HTTP 200 OK (Texte sans "error" ou "failed")
- **Type utilisé** : Client
- **Écran qui l'utilise** : Formulaire de création de client
- **Rôle de l'API** : Créer un nouveau client.

## 6. Tiers - Ajout Fournisseur
- **Nom** : Insert Supplier
- **URL** : `{baseUrl}Insert_tiers.php`
- **Endpoint** : `Insert_tiers.php`
- **GET ou POST** : GET
- **Paramètres** : `IDTiers`, `Nom`, `Adresse`, `Telephone`, `NIS`, `NAI`, `NIF`, `Solde`, `Type` (fixé à 2), `AjoutePar`, `NRC`, `RIB`, `GestionDeFidelite`, `Note`, `Facebook`, `AncienSolde`
- **Exemple de requête** : `Insert_tiers.php?IDTiers=0&Nom=SocieteX&Type=2...`
- **Réponse attendue** : Code HTTP 200 OK
- **Type utilisé** : Supplier
- **Écran qui l'utilise** : Formulaire de création de fournisseur
- **Rôle de l'API** : Créer un nouveau fournisseur.

## 7. Tiers - Liste Clients
- **Nom** : Fetch Clients
- **URL** : `{baseUrl}liste_client.php`
- **Endpoint** : `liste_client.php`
- **GET ou POST** : GET
- **Paramètres** : `Type` (fixé à 1)
- **Exemple de requête** : `liste_client.php?Type=1`
- **Réponse attendue** : Tableau JSON des clients
- **Type utilisé** : `ClientModel`
- **Écran qui l'utilise** : Liste des clients, Écrans de ventes
- **Rôle de l'API** : Récupérer la liste de tous les clients.

## 8. Tiers - Liste Fournisseurs
- **Nom** : Fetch Suppliers
- **URL** : `{baseUrl}liste_client.php`
- **Endpoint** : `liste_client.php`
- **GET ou POST** : GET
- **Paramètres** : `Type` (fixé à 2)
- **Exemple de requête** : `liste_client.php?Type=2`
- **Réponse attendue** : Tableau JSON des fournisseurs
- **Type utilisé** : `FournisseurModel`
- **Écran qui l'utilise** : Liste des fournisseurs, Écrans d'achats
- **Rôle de l'API** : Récupérer la liste de tous les fournisseurs.

## 9. Documents - Lignes de Document
- **Nom** : Fetch Document Lines
- **URL** : `{baseUrl}Liste_LigneDoc.php`
- **Endpoint** : `Liste_LigneDoc.php`
- **GET ou POST** : GET
- **Paramètres** : `ID` (0), `IDDocument`
- **Exemple de requête** : `Liste_LigneDoc.php?ID=0&IDDocument=105`
- **Réponse attendue** : Tableau JSON contenant les lignes (produits) du document
- **Type utilisé** : `DocumentLineModel`
- **Écran qui l'utilise** : Détail d'une vente / d'un achat
- **Rôle de l'API** : Charger les articles qui composent un document spécifique.

## 10. Documents - Ajout / Entête (Vente / Achat)
- **Nom** : Insert Document
- **URL** : `{baseUrl}Insert_document.php`
- **Endpoint** : `Insert_document.php`
- **GET ou POST** : GET
- **Paramètres** : `Date`, `Heure`, `Remise`, `Total`, `IDTiers`, `Benefice`, `Numero`, `Type` (5 pour achat, 6 pour vente), `Rendu`, `Versement`, `Reste`, `AjoutePar`, `ModifierPar`, `Image`, `DateAjout`, `DateModification`, `HeureModification`, `IDTypeTarifs`, `IDMotifEntreeSortieStock`, `DocCommande`, `Etabli_par`, `Enattente`, `DocRetour`, `Regle`, `TotalTVA`, `TotalHT`, `IDDocument` (optionnel)
- **Exemple de requête** : `Insert_document.php?Total=100&Type=6&IDTiers=3...`
- **Réponse attendue** : Objet JSON ou texte contenant le nouvel `IDDocument`
- **Type utilisé** : Achat / Vente Document
- **Écran qui l'utilise** : Création d'une vente ou d'un achat
- **Rôle de l'API** : Créer l'entête d'une facture/document et récupérer son ID SAGE.

## 11. Documents - Ajout Ligne
- **Nom** : Insert Document Line
- **URL** : `{baseUrl}Insert_LigneDocument.php`
- **Endpoint** : `Insert_LigneDocument.php`
- **GET ou POST** : GET
- **Paramètres** : Paramètres de la ligne (`IDDocument`, attributs de prix, quantité, index)
- **Exemple de requête** : `Insert_LigneDocument.php?IDDocument=105&Qte=2...`
- **Réponse attendue** : Code HTTP 200 OK
- **Type utilisé** : `SaleLineModel`, `PurchaseLineModel`
- **Écran qui l'utilise** : Création d'une vente ou d'un achat
- **Rôle de l'API** : Ajouter un produit dans un document existant.

## 12. Documents - Suppression Document
- **Nom** : Delete Document
- **URL** : `{baseUrl}delete_Document.php`
- **Endpoint** : `delete_Document.php`
- **GET ou POST** : GET
- **Paramètres** : `ID`
- **Exemple de requête** : `delete_Document.php?ID=105`
- **Réponse attendue** : Code HTTP 200 OK
- **Type utilisé** : Document
- **Écran qui l'utilise** : Liste ou Détail des ventes/achats
- **Rôle de l'API** : Supprimer un document (vente ou achat).

## 13. Documents - Suppression Ligne
- **Nom** : Delete Document Line
- **URL** : `{baseUrl}Delete_LigneDocument.php`
- **Endpoint** : `Delete_LigneDocument.php`
- **GET ou POST** : GET
- **Paramètres** : `ID`
- **Exemple de requête** : `Delete_LigneDocument.php?ID=55`
- **Réponse attendue** : Code HTTP 200 OK
- **Type utilisé** : Ligne Document
- **Écran qui l'utilise** : Édition d'un document
- **Rôle de l'API** : Supprimer une ligne spécifique à l'intérieur d'un document.

## 14. Documents - Liste Achats
- **Nom** : Fetch Purchases Documents
- **URL** : `{baseUrl}liste_doc.php`
- **Endpoint** : `liste_doc.php`
- **GET ou POST** : GET
- **Paramètres** : `Type` (fixé à 3), `DateDebut`, `DateFin`
- **Exemple de requête** : `liste_doc.php?Type=3&DateDebut=2023-01-01&DateFin=2023-12-31`
- **Réponse attendue** : Tableau JSON des documents
- **Type utilisé** : `PurchaseModel`
- **Écran qui l'utilise** : Liste des achats
- **Rôle de l'API** : Récupérer l'historique des bons d'achat.

## 15. Documents - Liste Ventes
- **Nom** : Fetch Sales Documents
- **URL** : `{baseUrl}liste_doc.php`
- **Endpoint** : `liste_doc.php`
- **GET ou POST** : GET
- **Paramètres** : `Type` (fixé à 1), `DateDebut`, `DateFin`
- **Exemple de requête** : `liste_doc.php?Type=1&DateDebut=2023-01-01&DateFin=2023-12-31`
- **Réponse attendue** : Tableau JSON des documents
- **Type utilisé** : `SaleModel`
- **Écran qui l'utilise** : Liste des ventes
- **Rôle de l'API** : Récupérer l'historique des bons de vente.

## 16. Produits - Liste (Stock)
- **Nom** : Fetch Products
- **URL** : `{baseUrl}liste_stock.php`
- **Endpoint** : `liste_stock.php`
- **GET ou POST** : GET
- **Paramètres** : Aucun paramètre obligatoire visible
- **Exemple de requête** : `liste_stock.php`
- **Réponse attendue** : Tableau JSON des produits
- **Type utilisé** : `ProductModel`
- **Écran qui l'utilise** : Liste des produits, Création de documents
- **Rôle de l'API** : Récupérer l'état actuel du stock et le catalogue produit.

## 17. Produits - Mise à jour & Stock
- **Nom** : Update Product & Stock
- **URL** : `{baseUrl}update_produit.php`
- **Endpoint** : `update_produit.php`
- **GET ou POST** : GET
- **Paramètres** : `IDProduit`, `Libelle`, `Qte`, `PrixVente`, `PrixAchat`, `Reference`
- **Exemple de requête** : `update_produit.php?IDProduit=1&Qte=15&PrixVente=200...`
- **Réponse attendue** : Code HTTP 200 OK
- **Type utilisé** : Product
- **Écran qui l'utilise** : Validation d'achat/vente, Modification de produit
- **Rôle de l'API** : Mettre à jour les informations d'un produit et/ou incrémenter/décrémenter la quantité en stock.

## 18. Produits - Ajout Nouveau
- **Nom** : Insert Product
- **URL** : `{baseUrl}insert_stock.php`
- **Endpoint** : `insert_stock.php`
- **GET ou POST** : GET
- **Paramètres** : `Libelle`, `Qte`, `PrixVente`, `PrixAchat`, `Reference`
- **Exemple de requête** : `insert_stock.php?Libelle=NouveauProduit&Qte=10...`
- **Réponse attendue** : Code HTTP 200 OK (Texte sans "error")
- **Type utilisé** : Product
- **Écran qui l'utilise** : Formulaire d'ajout de produit
- **Rôle de l'API** : Insérer un nouveau produit dans le stock SAGE.

## 19. Produits - Codes-barres (Lecture)
- **Nom** : Get Barcodes By Product
- **URL** : `{baseUrl}liste_CodeBareByProduit.php`
- **Endpoint** : `liste_CodeBareByProduit.php`
- **GET ou POST** : GET
- **Paramètres** : `ID` (ID du produit)
- **Exemple de requête** : `liste_CodeBareByProduit.php?ID=42`
- **Réponse attendue** : Tableau JSON des codes-barres
- **Type utilisé** : `BarcodeModel`
- **Écran qui l'utilise** : Scanner, Détail Produit
- **Rôle de l'API** : Récupérer tous les codes-barres associés à un produit.

## 20. Produits - Codes-barres (Ajout)
- **Nom** : Add Barcode
- **URL** : `{baseUrl}Insert_CodeBare.php`
- **Endpoint** : `Insert_CodeBare.php`
- **GET ou POST** : GET
- **Paramètres** : `CodeBarre`, `IDProduit`, `Colis`
- **Exemple de requête** : `Insert_CodeBare.php?CodeBarre=123456789&IDProduit=42&Colis=0`
- **Réponse attendue** : Code texte se terminant par '1' (Succès)
- **Type utilisé** : Barcode
- **Écran qui l'utilise** : Édition Produit, Scanner
- **Rôle de l'API** : Associer un nouveau code-barres à un produit.

## 21. Situation (Clients / Fournisseurs)
- **Nom** : Load Situation
- **URL** : `{baseUrl}situation.php`
- **Endpoint** : `situation.php`
- **GET ou POST** : GET
- **Paramètres** : `IDTiers`
- **Exemple de requête** : `situation.php?IDTiers=5`
- **Réponse attendue** : Tableau JSON avec l'historique de situation
- **Type utilisé** : `SituationModel`
- **Écran qui l'utilise** : Situation du Tiers
- **Rôle de l'API** : Charger l'historique financier ou le solde d'un client ou d'un fournisseur.

## 22. Versements - Liste
- **Nom** : Load Versements
- **URL** : `{baseUrl}Liste_versement.php`
- **Endpoint** : `Liste_versement.php`
- **GET ou POST** : GET
- **Paramètres** : `DateDebut`, `DateFin`
- **Exemple de requête** : `Liste_versement.php?DateDebut=2023-01-01&DateFin=2023-12-31`
- **Réponse attendue** : Objet JSON contenant une clé `data` avec le tableau
- **Type utilisé** : `VersementModel`
- **Écran qui l'utilise** : Liste des Versements
- **Rôle de l'API** : Récupérer l'historique des paiements (versements).

## 23. Versements - Ajout
- **Nom** : Insert Versement
- **URL** : `{baseUrl}Insert_versement.php`
- **Endpoint** : `Insert_versement.php`
- **GET ou POST** : GET
- **Paramètres** : `IDVersementTiers`, `Date`, `Heure`, `Montant`, `IDTiers`, `ModeReglement`, `AjoutePar`, `ModifiePar`, `DateAjout`, `Type`, `Paye`, `DateEcheance`, `Observation`, `Motif`, `HeureAjout`
- **Exemple de requête** : `Insert_versement.php?IDTiers=5&Montant=1500...`
- **Réponse attendue** : Code HTTP 200 OK
- **Type utilisé** : `VersementModel`
- **Écran qui l'utilise** : Ajout de versement
- **Rôle de l'API** : Enregistrer un nouveau paiement.

## 24. Statistiques
- **Nom** : Fetch Statistics
- **URL** : `{baseUrl}statistique.php`
- **Endpoint** : `statistique.php`
- **GET ou POST** : GET
- **Paramètres** : `DateDebut`, `DateFin`
- **Exemple de requête** : `statistique.php?DateDebut=2023-01-01&DateFin=2023-12-31`
- **Réponse attendue** : Tableau JSON de données statistiques
- **Type utilisé** : `StatisticsModel`
- **Écran qui l'utilise** : Dashboard / Écran Statistiques
- **Rôle de l'API** : Récupérer les données globales (ventes, achats, charges) sur une période pour l'affichage des graphiques et indicateurs.
