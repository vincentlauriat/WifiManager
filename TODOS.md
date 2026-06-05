# TODOS — WifiManager

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
- [x] Localisation FR/EN sélectionnable dans les Préférences
- [x] Auto-update Sparkle 2 (clé EdDSA générée, appcast configurable)
- [x] README anglais avec badges, roadmap, instructions build
- [x] Dépôt GitHub public (https://github.com/vincentlauriat/WifiManager)
