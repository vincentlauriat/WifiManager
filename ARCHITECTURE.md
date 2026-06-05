# Architecture — WifiManager

## Vue d'ensemble

```
┌─────────────────────────────────────────────────────┐
│                  Menu Bar macOS                      │
│         (icône rouge / orange / verte)               │
└─────────────────────┬───────────────────────────────┘
                      │ clic
                      ▼
┌─────────────────────────────────────────────────────┐
│       WifiManager.app  (SwiftUI, macOS 13+)          │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │            MenuBarExtra (.window)            │    │
│  │  ┌────────────────────────────────────────┐  │    │
│  │  │           MenuBarView                  │  │    │
│  │  │  ├─ StatusHeaderView  (SSID + badge)   │  │    │
│  │  │  ├─ MetricsView       (RSSI, latence)  │  │    │
│  │  │  ├─ UsageScoresView   (mail, visio…)   │  │    │
│  │  │  ├─ Actions           (reconnect, scan)│  │    │
│  │  │  └─ NetworkListView   (réseaux dispo)  │  │    │
│  │  └────────────────────────────────────────┘  │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │            Services (@MainActor)             │    │
│  │  ┌─────────────────┐  ┌──────────────────┐  │    │
│  │  │   WiFiMonitor   │  │LocationProfileMgr│  │    │
│  │  │  ObservableObject│  │ ObservableObject │  │    │
│  │  └────────┬────────┘  └──────────────────┘  │    │
│  │           │                                  │    │
│  │  ┌────────┴────────────────────────────────┐ │    │
│  │  │  CoreWLAN      Network    CoreLocation  │ │    │
│  │  │  CWWiFiClient  NWPathMonitor  CLLocation│ │    │
│  │  └─────────────────────────────────────────┘ │    │
│  └──────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

## Pile technique

| Couche | Choix | Raison |
|---|---|---|
| Langage | Swift 5.9+ | Natif macOS |
| UI | SwiftUI + MenuBarExtra | Barre de menu native macOS 13+ |
| WiFi | CoreWLAN (CWWiFiClient) | API Apple officielle pour SSID, RSSI, scan, association |
| Connectivité | Network.framework (NWPathMonitor) | Détection hotspot via `isExpensive`, changements de path |
| Localisation | CoreLocation (CLLocationManager) | Profils par lieu |
| Persistance | UserDefaults (JSON) | Profils de lieux sérialisés |
| Préférences | @AppStorage | Réglages simples |
| Concurrence | async/await + @MainActor | Swift Concurrency, sécurité des threads |

## Modules Swift

```
WifiManager/Sources/
├── WifiManagerApp.swift          — @main, MenuBarExtra + Settings scene, icône barre de menu
├── NetworkStatus.swift           — ConnectionStatus, NetworkQuality, NetworkMetrics
├── UsageProfile.swift            — UsageType (email, web, visio, gaming…) + calcul qualité
├── LocationProfile.swift         — struct LocationProfile (Codable, CLLocation matching)
│
├── WiFiMonitor.swift             — @MainActor ObservableObject central
│                                   CWWiFiClient + NWPathMonitor + polling 30 s
│                                   reconnect(), scanNetworks(), connect(to:password:)
├── NetworkQualityChecker.swift   — actor : test latence HEAD apple.com, cache 30 s
│                                   computeUsageScores() → [UsageType: NetworkQuality]
├── ConnectionTypeDetector.swift  — NWPathMonitor isolé, expose isExpensive / isConnected
├── LocationProfileManager.swift  — @MainActor ObservableObject, CLLocationManagerDelegate
│                                   CRUD profils (UserDefaults JSON)
│
├── WifiManagerApp.swift          — @main
├── MenuBarView.swift             — layout principal du popover (310 pt)
├── StatusHeaderView.swift        — badge coloré + SSID + canal + horodatage
├── MetricsView.swift             — barres RSSI / latence / débit / SNR
├── UsageScoresView.swift         — grille 3×2 icônes colorées par usage
├── NetworkListView.swift         — liste réseaux avec prompt mot de passe inline
└── SettingsView.swift            — TabView : Général / Lieux / À propos
```

## Flux de données

### Démarrage
1. `WifiManagerApp` crée `WiFiMonitor` et `LocationProfileManager` comme `@StateObject`
2. `WiFiMonitor.init` : `NWPathMonitor` démarre + `Task { await refresh() }` + `Timer` 30 s
3. `refresh()` lit `CWInterface` (SSID, RSSI, bruit, débit), appelle `NetworkQualityChecker.measureLatency()`
4. Met à jour `status`, `metrics`, `usageScores` → SwiftUI re-rend l'icône et le popover

### Détection hotspot
1. `ConnectionTypeDetector` maintient un `NWPathMonitor` dédié
2. `NWPath.isExpensive == true` → connexion coûteuse (partage iPhone/Android, cellulaire)
3. `WiFiMonitor` crée `ConnectionStatus.hotspot(quality:)` au lieu de `.wifi(quality:)`
4. L'icône affiche un badge `personalhotspot` orange à côté du symbole wifi

### Mesure de latence
1. `NetworkQualityChecker.measureLatency()` : requête HEAD `apple.com/library/test/success.html`
2. Résultat mis en cache 30 s pour éviter les requêtes inutiles
3. Cache invalidé lors d'un changement de path (`NWPathMonitor`) ou d'une reconnexion
4. La latence alimente `NetworkQuality.from(rssi:latency:)` et `UsageType.quality(latency:download:)`

### Scores d'usage
Chaque `UsageType` définit un seuil `(latencyMs, downloadMbps)`. Le score est calculé :
- 0–33% → Mauvaise (rouge)
- 34–59% → Correcte (orange)
- 60–79% → Bonne (vert)
- 80–100% → Excellente (vert)

### Scan et connexion
1. `WiFiMonitor.scanNetworks()` : `CWInterface.scanForNetworks()` sur `DispatchQueue.global` (bloquant ~2-8 s)
2. Réseaux triés par RSSI décroissant, affichés dans `NetworkListView`
3. Réseau ouvert → `CWInterface.associate(to:password:"")` direct
4. Réseau sécurisé → prompt mot de passe inline → `associate(to:password:pwd)`
5. Réseau connu (dans le keychain) → `associate(to:password:nil)` (CoreWLAN lit le keychain)

### Profils de lieux
1. `LocationProfileManager` gère `[LocationProfile]` persisté en JSON dans `UserDefaults`
2. `CLLocationManager` avec `distanceFilter: 100 m` et `desiredAccuracy: 100 m`
3. Sur changement de position, `matchProfile(to:)` compare avec `CLLocation.distance`
4. Le profil actif est affiché dans le pied de page du popover

## Points d'attention

- **Non-sandboxé** : requis pour que `CWWiFiClient` puisse scanner et s'associer à des réseaux sans entitlement spécifique Apple Developer.
- **`scanForNetworks` bloquant** : exécuté sur `DispatchQueue.global(qos: .userInitiated)` via `withCheckedThrowingContinuation` pour ne pas bloquer le main thread.
- **Cache latence** : la latence est testée avec un HEAD sur apple.com, ce qui mesure le RTT applicatif (DNS inclus). Pas un ping ICMP, mais suffisant pour évaluer la qualité perçue.
- **`CWNetwork` rétroactive Identifiable** : conformance via `@retroactive` (Swift 5.7+) basée sur `bssid ?? ssid ?? hashValue`. Le BSSID est unique par point d'accès, le SSID peut avoir des doublons.
- **`NWPath.isExpensive`** : fiable pour détecter iPhone Personal Hotspot et partages Android, mais retourne `false` si le Mac est branché en Ethernet via le téléphone (rare).
- **Permissions localisation** : non demandées au démarrage. L'utilisateur active les profils de lieux dans les Réglages, ce qui déclenche la demande.
