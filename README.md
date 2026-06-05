# WifiManager

Application macOS de surveillance WiFi dans la barre de menu.

## Fonctionnalités

- **Icône de statut** : rouge (déconnecté), orange (problèmes), verte (tout va bien)
- **Métriques temps réel** : RSSI, latence, débit du lien, SNR
- **Scores par usage** : e-mail, navigation, visio (Teams/Meet), gaming, streaming
- **Reconnexion en un clic** : déconnecte et reconnecte au même réseau
- **Scan des réseaux** : liste les réseaux disponibles avec force du signal et cadenas si sécurisé
- **Changement de réseau** : connexion directe depuis le popover (avec saisie du mot de passe intégrée)
- **Détection partage de connexion** : distingue un vrai WiFi d'un partage iPhone/Android (`NWPath.isExpensive`)
- **Profils de lieux** : associe un SSID préféré à un lieu (maison, bureau…), avec détection automatique via CoreLocation

## Pile technique

| Composant | Technologie |
|---|---|
| UI | SwiftUI + MenuBarExtra |
| WiFi | CoreWLAN (CWWiFiClient) |
| Connectivité | Network.framework (NWPathMonitor) |
| Localisation | CoreLocation |
| macOS minimum | 13.0 |
| Langage | Swift 5.9+ |

## Installation

### Prérequis

- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
```

### Générer le projet et compiler

```bash
cd WifiManager
xcodegen generate
open WifiManager.xcodeproj
```

Puis **Cmd+R** dans Xcode.

## Structure du projet

```
WifiManager/
├── project.yml                   # Configuration XcodeGen (source de vérité)
├── ARCHITECTURE.md               # Architecture détaillée
├── TODOS.md                      # Tâches en cours
├── WifiManager/
│   ├── Sources/
│   │   ├── WifiManagerApp.swift          # @main + MenuBarExtra
│   │   ├── NetworkStatus.swift           # Modèles de statut
│   │   ├── UsageProfile.swift            # Profils d'usage
│   │   ├── LocationProfile.swift         # Modèle de lieu
│   │   ├── WiFiMonitor.swift             # Service de surveillance central
│   │   ├── NetworkQualityChecker.swift   # Tests de latence
│   │   ├── ConnectionTypeDetector.swift  # Détection hotspot
│   │   ├── LocationProfileManager.swift  # Gestion des profils de lieux
│   │   ├── MenuBarView.swift             # Popover principal
│   │   ├── StatusHeaderView.swift        # En-tête avec badge coloré
│   │   ├── MetricsView.swift             # Barres de métriques
│   │   ├── UsageScoresView.swift         # Grille de scores par usage
│   │   ├── NetworkListView.swift         # Liste des réseaux disponibles
│   │   └── SettingsView.swift            # Fenêtre de préférences
│   └── Resources/
│       └── Assets.xcassets/
└── .gitignore
```

## Roadmap

- [x] Icône barre de menu rouge/orange/vert
- [x] Métriques RSSI, latence, débit, SNR
- [x] Scores par usage (mail, navigation, visio, gaming, streaming)
- [x] Reconnexion en un clic
- [x] Scan et changement de réseau WiFi
- [x] Détection partage de connexion vs WiFi réel
- [x] Profils de lieux avec CoreLocation
- [ ] Historique de connexion (graphe temporel)
- [ ] Test de débit réel (upload/download)
- [ ] Notifications système (déconnexion, dégradation)
- [ ] Lancement au démarrage (LaunchAgent)
- [ ] Export des métriques CSV
