# TODOS — WifiManager

## En cours

- [ ] Générer le projet Xcode via `xcodegen generate` et vérifier la compilation
- [ ] Tester sur un Mac avec WiFi actif
- [ ] Tester la détection hotspot (partage iPhone)

## À faire — v1.1

- [ ] Test de débit réel (download) via URLSession sur un endpoint dédié
- [ ] Notifications système : alerte si connexion perdue ou dégradée
- [ ] Historique 24 h du RSSI et de la latence (graphe SwiftUI Charts)
- [ ] Lancement au démarrage via LaunchAgent ou SMAppService (macOS 13+)

## À faire — v1.2

- [ ] Export CSV des métriques (RSSI, latence, débit) sur période choisie
- [ ] Support multi-interface (plusieurs cartes WiFi)
- [ ] Raccourci clavier global pour ouvrir le popover
- [ ] Icône app personnalisée (PNG 512×512)

## Terminé — v1.0

- [x] Icône barre de menu colorée (rouge/orange/vert)
- [x] Détection statut connexion via CWWiFiClient + NWPathMonitor
- [x] Métriques RSSI, latence, débit lien, SNR avec barres animées
- [x] Scores qualité par usage (mail, navigation, visio, gaming, streaming)
- [x] Reconnexion (disassociate + scan + re-associate)
- [x] Scan et liste des réseaux disponibles
- [x] Connexion à un réseau (ouvert ou sécurisé avec prompt inline)
- [x] Détection partage de connexion via NWPath.isExpensive
- [x] Profils de lieux (CoreLocation + UserDefaults JSON)
- [x] Fenêtre de préférences (Général / Lieux / À propos)
- [x] Structure XcodeGen (project.yml)
