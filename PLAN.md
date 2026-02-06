# Plan complet : BarPath - Meilleure app de bar path tracking sur l'App Store

## Contexte

BarPath est une app iOS de tracking de trajectoire de barre utilisant le framework Vision (détection de pose des poignets). L'architecture (MVVM + Services, Swift 6, SwiftUI) est solide, 166 tests passent, le projet compile sans erreurs. Mais **l'app n'est pas fonctionnelle** : l'enregistrement vidéo est un stub, le flux bout-en-bout ne marche pas, et il manque tout le polish production.

**Marché :** 11 concurrents identifiés (Metric VBT, WL Analysis, Iron Path, BarSense...). La plainte #1 des utilisateurs est **la fiabilité de la détection**. Opportunité : app phone-only, précise, prix juste, sans matériel.

**Objectif :** Devenir LA référence bar path tracking sur l'App Store.

---

## Phase 1 : Core fonctionnel (Agent Team : 3 teammates)

> Priorité absolue : faire marcher le flux enregistrer → analyser → résultat.

### 1.1 Enregistrement vidéo réel
**Teammate "Capture"**

- **Fichiers :** `BarPath/ViewModels/RecordViewModel.swift`, `BarPath/Views/Record/RecordView.swift`, `BarPath/Services/Protocols/CameraManaging.swift`
- Implémenter `AVCaptureMovieFileOutput` dans `RecordViewModel`
  - Ajouter le output au `captureSession` (via `SessionRunner`)
  - Implémenter `AVCaptureFileOutputRecordingDelegate`
  - Gérer start/stop réels (pas de placeholder URL)
  - Configurer le frame rate (30/60fps selon `AppSettings`)
  - Écrire le fichier `.mov` dans le dossier temporaire
- Ajouter la gestion des permissions caméra
  - Vérifier `AVCaptureDevice.authorizationStatus(for: .video)` avant setup
  - Afficher un message et bouton "Ouvrir les réglages" si refusé
  - Ajouter UI d'erreur dans `RecordView` quand caméra indisponible
- Connecter le flux navigation : après `stopRecording()`, naviguer vers `AnalysisProgressView` avec la vraie URL vidéo

### 1.2 Pipeline d'analyse bout-en-bout
**Teammate "Analysis"**

- **Fichiers :** `BarPath/ViewModels/AnalysisViewModel.swift`, `BarPath/Services/VideoProcessingService.swift`, `BarPath/Views/Result/AnalysisProgressView.swift`
- Vérifier et tester le flux complet :
  1. `VideoProcessingService.processVideo(at:)` extrait les frames → détecte les poses
  2. `BarPathAnalyzer.analyze()` lisse → calcule vélocités → détecte reps → métriques
  3. `AnalysisViewModel` orchestre tout et met à jour le `progress`
- Fixer `AnalysisProgressView` :
  - Connecter la navigation vers `ResultView` quand l'analyse est terminée
  - Ajouter bouton "Retry" fonctionnel en cas d'erreur
- Fixer le bug de navigation dans `HomeView` : l'import vidéo (PhotosPicker) assigne `importedVideoURL` mais ne navigue nulle part → naviguer vers `AnalysisProgressView`
- Ajouter résilience : si un frame échoue la détection, continuer (ne pas crasher)
- Ajouter validation min/max durée de rep dans `RepDetectionService`

### 1.3 Résultats et export
**Teammate "Results"**

- **Fichiers :** `BarPath/Views/Result/ResultView.swift`, `BarPath/ViewModels/ResultViewModel.swift`, `BarPath/Services/ExportService.swift`
- Fixer `ExportService.swift` :
  - Bug ligne 291 : `CVPixelBufferLockBaseAddress` avec `.readOnly` mais modification du buffer → créer une copie du pixel buffer avant modification
  - Corriger le mapping vélocité/couleur (index-based → timestamp-based)
- Connecter l'export dans `ResultView` :
  - Ajouter bouton "Exporter la vidéo" qui appelle `ExportService.exportVideo()`
  - Ajouter bouton "Enregistrer dans Photos" qui appelle `ExportService.saveToPhotosLibrary()`
  - Afficher une barre de progression pendant l'export
- Fixer `ShareLink` dans `ResultView` : partager la vidéo exportée (pas juste du texte)
- Afficher la vidéo avec overlay dans le player (pas la vidéo originale)

### Vérification Phase 1
```bash
xcodebuild build -scheme BarPath -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test -scheme BarPath -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
# Test manuel sur device : Record → Analyze → Results → Export
```

---

## Phase 2 : Précision et fiabilité (Agent Team : 2-3 teammates)

> La plainte #1 des concurrents est l'imprécision. On doit être meilleur.

### 2.1 Amélioration de la détection
- **Fichier :** `BarPath/Services/PoseDetectionService.swift`
- Tracker les DEUX poignets et calculer le point médian (meilleure approximation de la barre)
- Ajouter fallback : si les poignets ne sont pas détectés, essayer les coudes
- Implémenter un filtre de Kalman léger pour lisser le tracking en temps réel
- Ajouter un score de qualité de détection par frame (% de frames avec détection réussie)
- Supporter les orientations portrait ET paysage

### 2.2 Overlay temps réel pendant l'enregistrement
- **Fichiers :** `BarPath/Views/Record/RecordView.swift`, `BarPath/ViewModels/RecordViewModel.swift`
- Ajouter `AVCaptureVideoDataOutput` pour obtenir les frames en live
- Afficher le bar path en temps réel sur le preview caméra pendant l'enregistrement
- Feedback visuel : point qui suit la barre en direct
- Feedback audio optionnel : bip de vélocité (comme Metric VBT)

### 2.3 Tests de précision
- Écrire des tests d'intégration avec des données de référence
- Tester avec différents angles de caméra et éclairages
- Documenter les limitations (distance min/max, angle optimal)

---

## Phase 3 : Features différenciantes (Agent Team : 3 teammates)

> Ce qui fait la différence avec les concurrents.

### 3.1 Comparaison côte-à-côte
- **Nouveaux fichiers :** `BarPath/Views/Comparison/ComparisonView.swift`, `BarPath/ViewModels/ComparisonViewModel.swift`
- Sélectionner 2 analyses et les comparer visuellement
- Superposer les bar paths (normalisés) avec des couleurs différentes
- Afficher les métriques en tableau comparatif
- Synchroniser la lecture vidéo des deux enregistrements

### 3.2 Estimation du 1RM
- **Nouveau fichier :** `BarPath/Services/OneRMCalculator.swift`
- Profil charge-vélocité : tracker la vélocité à différentes charges
- Calculer le 1RM estimé via régression linéaire
- Afficher le graphique charge-vélocité avec courbe de tendance

### 3.3 Coaching intelligent
- **Nouveau fichier :** `BarPath/Services/CoachingService.swift`
- Analyser la trajectoire et générer des conseils textuels :
  - "Ta barre dérive de 3.2cm vers l'avant au milieu de la montée"
  - "La phase concentrique du rep 3 est 15% plus lente → fatigue détectée"
  - "Ton drift horizontal augmente à chaque rep → attention à la technique"
- Localisation FR/EN de tous les messages

### 3.4 Lecture frame-by-frame
- **Fichier :** `BarPath/Views/Result/ResultView.swift`
- Slider pour scrubber image par image
- Afficher le point de tracking et les métriques instantanées par frame

---

## Phase 4 : Production polish (Agent Team : 3 teammates)

### 4.1 UI/UX Polish
**Teammate "Design"**

- **Nouveau :** `BarPath/Utils/DesignTokens.swift` — couleurs adaptatives light/dark/tinted (pattern LoadSense)
- **Nouveau :** `BarPath/Utils/HapticManager.swift` — haptics sur record/stop/rep détecté/analyse terminée (pattern TempoReps)
- **Nouveau :** `BarPath/Utils/AccessibilityExtensions.swift` — VoiceOver labels, Dynamic Type, hints
- Dark mode complet sur toutes les vues
- Animations fluides : transitions, progress ring, bar path drawing
- Loading states avec skeleton views

### 4.2 StoreKit et modèle économique
**Teammate "Monetization"**

- **Nouveau :** `BarPath/Services/StoreKitManager.swift` — StoreKit 2, Keychain trial (pattern LoadSense)
- **Nouveau :** `BarPath/Views/PaywallView.swift`
- **Tier gratuit :** 3 analyses, fonctionnalités de base
- **Achat unique (6.99€) :** `app.barpath.lifetime` — tout illimité, toutes futures features
- **Nouveau :** `Configuration.storekit` pour les tests

### 4.3 Finitions
- Review prompt : bouton "Note l'app" dans Settings (SKStoreReviewController)
- Pas d'onboarding formel (comme LoadSense/TempoReps) — valeur immédiate
- Tooltip contextuel premier enregistrement : "Place ton iPhone à ~1.5m, de profil"

---

## Phase 5 : App Store (Agent Team : 2 teammates)

### 5.1 Metadata et screenshots
**Teammate "Store"**

- **Créer :** `fastlane/metadata/` (structure identique à LoadSense)
  - `copyright.txt` → "© 2026 Benjamin Dupin"
  - `primary_category.txt` → "Health & Fitness"
  - `en-US/name.txt` → "BarPath - Bar Tracker"
  - `en-US/subtitle.txt` → "Track your barbell path"
  - `en-US/keywords.txt` → "barpath,barbell,tracking,squat,deadlift,bench,VBT,velocity,powerlifting,weightlifting"
  - `fr-FR/` → traductions complètes
  - `review_information/` → contact info
- **Créer :** `fastlane/Snapfile` — 3 devices × 2 langues × 5 screenshots
- **Créer :** `BarPathUITests/BarPathUITests.swift` — screenshot automation
- Icône app : 1024×1024 light + dark + tinted variants

### 5.2 Privacy et compliance
**Teammate "Compliance"**

- Mettre à jour `BarPath/PrivacyInfo.xcprivacy` : ajouter Vision, Camera, Photos API
- Vérifier toutes les localisations EN/FR complètes
- URL politique de confidentialité + URL support
- Configurer Matchfile pour code signing

### Vérification Phase 5
```bash
xcodebuild build -scheme BarPath -configuration Release -destination generic/platform=iOS
xcodebuild test -scheme BarPath -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
bundle exec fastlane screenshots
bundle exec fastlane release --dry_run
```

---

## Phase 6 : Post-launch (futur)

- Apple Watch companion
- Export CSV/JSON pour coaches
- Intégration Apple Health
- Widget iOS
- Profils charge-vélocité historiques
- Détection automatique du type de lift (ML)

---

## Fichiers critiques

### Existants à modifier :
| Fichier | Modification |
|---------|-------------|
| `BarPath/ViewModels/RecordViewModel.swift` | Enregistrement vidéo réel (AVCaptureMovieFileOutput) |
| `BarPath/Views/Record/RecordView.swift` | UI permissions caméra + erreurs |
| `BarPath/ViewModels/AnalysisViewModel.swift` | Pipeline complet + navigation |
| `BarPath/Views/Result/AnalysisProgressView.swift` | Navigation vers résultats |
| `BarPath/Views/Result/ResultView.swift` | Export + share vidéo |
| `BarPath/Services/ExportService.swift` | Fix pixel buffer bug |
| `BarPath/Services/PoseDetectionService.swift` | Tracking bilatéral + Kalman |
| `BarPath/Services/RepDetectionService.swift` | Validation min/max durée |
| `BarPath/Views/HomeView.swift` | Fix navigation import vidéo |
| `BarPath/PrivacyInfo.xcprivacy` | Déclarations API manquantes |

### Nouveaux fichiers :
| Fichier | Description |
|---------|-------------|
| `BarPath/Utils/HapticManager.swift` | Feedback haptique |
| `BarPath/Utils/DesignTokens.swift` | Couleurs adaptatives, spacing |
| `BarPath/Utils/AccessibilityExtensions.swift` | VoiceOver, Dynamic Type |
| `BarPath/Services/StoreKitManager.swift` | Achats in-app StoreKit 2 |
| `BarPath/Services/OneRMCalculator.swift` | Estimation 1RM |
| `BarPath/Services/CoachingService.swift` | Conseils intelligents |
| `BarPath/Views/PaywallView.swift` | Paywall |
| `BarPath/Views/Comparison/ComparisonView.swift` | Comparaison analyses |
| `BarPath/ViewModels/ComparisonViewModel.swift` | VM comparaison |
| `BarPathUITests/BarPathUITests.swift` | Screenshots automatisés |
| `fastlane/Snapfile` | Config screenshots |
| `fastlane/metadata/**` | Metadata App Store |
| `Configuration.storekit` | Config StoreKit test |
