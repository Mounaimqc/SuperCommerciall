# Tasks - Alignement et Robustesse du Scanner

## 🎨 1. Alignement Graphique & Comportement de défilement
- [x] Aligner le padding, l'espacement et la physique de défilement de `lib/screens/purchases_screen.dart` sur ceux de `lib/screens/sales_screen.dart`
- [x] Utiliser la couleur `AppConstants.purpleCardColor` pour le `RefreshIndicator` des Achats
- [x] Configurer la couleur du bouton flottant d'ajout d'achat sur `AppConstants.blueCardColor` pour correspondre à la carte tableau de bord

## 📷 2. Robustesse du Scanner de Code-barres
- [x] Vérifier et demander la permission caméra au lancement de `BarcodeScannerScreen`
- [x] Afficher une boîte de dialogue explicative avec redirections en cas de refus d'accès
- [x] Gérer le cycle de vie de la caméra (observer `WidgetsBindingObserver`) pour éviter les écrans noirs au retour en premier plan
- [x] Afficher un écran d'erreur spécifique en cas de problème de démarrage caméra avec option "Réessayer"
- [x] Libérer proprement les ressources de la caméra lors de la fermeture de l'écran

## 🧪 3. Validation & Tests
- [x] Exécuter `flutter analyze` et s'assurer que tout est propre (0 issues)
- [x] Exécuter la suite complète de tests unitaires du projet
