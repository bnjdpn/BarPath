# Plan complet : BarPath - Meilleure app de bar path tracking sur l'App Store

## Contexte

BarPath est une app iOS de tracking de trajectoire de barre utilisant le framework Vision (détection de pose des poignets). L'architecture (MVVM + Services, Swift 6, SwiftUI) est solide, 166 tests passent, le projet compile sans erreurs. Mais **l'app n'est pas fonctionnelle** : l'enregistrement vidéo est un stub, le flux bout-en-bout ne marche pas, et il manque tout le polish production.

**Marché :** 11 concurrents identifiés (Metric VBT, WL Analysis, Iron Path, BarSense...). La plainte #1 des utilisateurs est **la fiabilité de la détection**. Opportunité : app phone-only, précise, prix juste, sans matériel.

**Objectif :** Devenir LA référence bar path tracking sur l'App Store. Quand le lead dit "terminé", l'app DOIT pouvoir être soumise à l'App Store.

---

## Agent Team : Organisation agile

### Composition de l'équipe (7 agents)

| Rôle | Responsabilité | Mode |
|------|---------------|------|
| **Lead (toi)** | Coordination, task assignment, synthèse, décisions d'architecture | Delegate mode (Shift+Tab) |
| **Backend Engineer** | Services, models, business logic, pipeline d'analyse, détection pose | Implémentation |
| **Capture Engineer** | Enregistrement vidéo, AVFoundation, caméra, permissions, overlay temps réel | Implémentation |
| **Frontend Engineer** | Toutes les Views, navigation, animations, dark mode, design system | Implémentation |
| **QA Engineer** | Tests unitaires, tests d'intégration, build verification, code review continu | Vérification |
| **DevOps Engineer** | CI/CD, Fastlane, metadata App Store, screenshots, StoreKit, privacy compliance | Configuration |
| **UX Reviewer** | Vérifie chaque écran via xcodebuild (build les previews), accessibilité, cohérence UI | Review |

### Règles de l'équipe

1. **Aucun fichier touché par 2 teammates en même temps** — le Lead assigne des ownership clairs
2. **Chaque teammate fait un plan approval avant d'implémenter**
3. **Le QA Engineer review après chaque merge de feature** — build + tests + code review
4. **Le UX Reviewer vérifie après chaque batch de changements UI** — screenshots simulator
5. **Zero warnings, zero tests failing à tout moment** — le QA bloque si c'est cassé
6. **Commit après chaque feature terminée** — pas de gros commits monolithiques

---

## Sprint 1 : Core fonctionnel

> Objectif : le flux Record → Analyze → Results → Export fonctionne de bout en bout.

### Capture Engineer

**Fichiers :** `RecordViewModel.swift`, `RecordView.swift`, `CameraManaging.swift`

1. Implémenter `AVCaptureMovieFileOutput` dans `RecordViewModel`
   - Ajouter le output au `captureSession` (via `SessionRunner`)
   - Implémenter `AVCaptureFileOutputRecordingDelegate`
   - Gérer start/stop réels (remplacer le placeholder URL)
   - Configurer le frame rate (30/60fps selon `AppSettings`)
   - Écrire le `.mov` dans le dossier temporaire
2. Gestion des permissions caméra
   - Vérifier `AVCaptureDevice.authorizationStatus(for: .video)` avant setup
   - UI d'erreur dans `RecordView` si caméra refusée + bouton "Ouvrir les réglages"
3. Connecter la navigation : après `stopRecording()` → `AnalysisProgressView` avec la vraie URL

### Backend Engineer

**Fichiers :** `AnalysisViewModel.swift`, `VideoProcessingService.swift`, `BarPathAnalyzer.swift`, `RepDetectionService.swift`

1. Vérifier et connecter le pipeline complet :
   - `VideoProcessingService.processVideo(at:)` → frames → poses
   - `BarPathAnalyzer.analyze()` → smooth → velocities → reps → metrics
   - `AnalysisViewModel` orchestre et update `progress`
2. Fixer le bug `HomeView` : import vidéo → navigation vers `AnalysisProgressView`
3. Résilience : si un frame échoue, continuer (ne pas crasher tout)
4. Validation min/max durée de rep dans `RepDetectionService`

### Frontend Engineer

**Fichiers :** `AnalysisProgressView.swift`, `ResultView.swift`, `HomeView.swift`

1. Fixer `AnalysisProgressView` : navigation vers `ResultView` quand analyse terminée
2. Fixer `ResultView` :
   - Ajouter boutons "Exporter vidéo" et "Enregistrer dans Photos"
   - Barre de progression pendant export
   - `ShareLink` partage la vidéo (pas du texte)
   - Afficher vidéo avec overlay (pas originale)
3. Fixer la navigation import vidéo dans `HomeView`

### Backend Engineer (suite)

**Fichier :** `ExportService.swift`

1. Fix bug pixel buffer : `CVPixelBufferLockBaseAddress(.readOnly)` mais modification → copier le buffer
2. Corriger mapping vélocité/couleur : index-based → timestamp-based

### QA Engineer — Vérification Sprint 1

```bash
xcodebuild build -scheme BarPath -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test -scheme BarPath -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
- Vérifier 0 warnings, 0 erreurs
- Ajouter tests pour les nouvelles fonctionnalités (RecordViewModel recording, ExportService fix)
- Code review de chaque fichier modifié

---

## Sprint 2 : Précision et overlay temps réel

> Objectif : tracking plus précis que tous les concurrents, overlay live pendant l'enregistrement.

### Backend Engineer

**Fichier :** `PoseDetectionService.swift`

1. Tracker les DEUX poignets et calculer le point médian (meilleure approximation barre)
2. Fallback : si poignets non détectés, essayer les coudes
3. Filtre de Kalman léger pour lisser le tracking
4. Score de qualité de détection par frame
5. Support orientations portrait ET paysage

### Capture Engineer

**Fichiers :** `RecordView.swift`, `RecordViewModel.swift`

1. Ajouter `AVCaptureVideoDataOutput` pour obtenir les frames live
2. Afficher le bar path en temps réel sur le preview caméra
3. Point qui suit la barre en direct
4. Feedback audio optionnel : bip de vélocité

### QA Engineer

1. Tests d'intégration avec données de référence (sine wave paths, etc.)
2. Tests des edge cases : pas de détection, un seul poignet, occlusion partielle
3. Build + run tests

### UX Reviewer

1. Vérifier l'overlay temps réel sur simulator (screenshot via xcodebuild)
2. Vérifier que le feedback est visible et non-intrusif
3. Vérifier les performances (pas de lag visible)

---

## Sprint 3 : Features différenciantes

> Objectif : ce qui fait que BarPath est MEILLEUR que les concurrents.

### Frontend Engineer

**Nouveaux fichiers :** `ComparisonView.swift`, `ComparisonViewModel.swift`

1. Comparaison côte-à-côte de 2 analyses
2. Superposition des bar paths normalisés (couleurs différentes)
3. Tableau comparatif des métriques
4. Lecture vidéo synchronisée

### Backend Engineer

**Nouveau fichier :** `OneRMCalculator.swift`

1. Profil charge-vélocité
2. Calcul 1RM via régression linéaire (Epley, Brzycki, VBT)
3. Graphique charge-vélocité avec courbe de tendance

**Nouveau fichier :** `CoachingService.swift`

1. Conseils textuels basés sur la trajectoire :
   - Drift détecté → "Ta barre dérive de Xcm vers l'avant"
   - Fatigue → "Rep N est X% plus lent"
   - Pattern → "Drift augmente à chaque rep"
2. Localisation FR/EN complète

### Frontend Engineer (suite)

**Fichier :** `ResultView.swift`

1. Lecture frame-by-frame avec slider
2. Point de tracking + métriques instantanées par frame
3. Affichage des conseils coaching sous les métriques

### QA Engineer

1. Tests unitaires pour `OneRMCalculator` et `CoachingService`
2. Tests de la comparaison (normalisation, alignement)
3. Build + run all tests

---

## Sprint 4 : Production polish

> Objectif : qualité App Store, pas une app de développeur.

### Frontend Engineer

**Nouveaux fichiers :** `DesignTokens.swift`, `HapticManager.swift`, `AccessibilityExtensions.swift`

1. Design system : couleurs adaptatives light/dark/tinted (pattern LoadSense `DarkModeExtensions.swift`)
2. Haptic feedback : record start/stop, rep détecté, analyse terminée, export terminé (pattern TempoReps `HapticsService`)
3. Accessibilité : VoiceOver labels sur tous les éléments, Dynamic Type, hints
4. Dark mode complet sur toutes les vues
5. Animations fluides : transitions entre écrans, progress ring, bar path drawing animé
6. Loading states propres (skeleton views, pas juste ProgressView)
7. Toggle haptics dans Settings

### DevOps Engineer

**Nouveaux fichiers :** `StoreKitManager.swift`, `PaywallView.swift`, `Configuration.storekit`

1. StoreKit 2 (pattern LoadSense) :
   - `app.barpath.lifetime` (6.99€) — achat unique
   - Trial 7 jours stocké en Keychain (pas UserDefaults)
   - Restore purchases
2. PaywallView avec preview features premium
3. Gating : 3 analyses gratuites, puis paywall
4. Configuration.storekit pour tests
5. Developer controls (simulator only, cachés en production)

### Frontend Engineer (suite)

1. Review prompt : bouton "Note l'app" dans Settings (`SKStoreReviewController`)
2. Tooltip premier enregistrement : "Place ton iPhone à ~1.5m, de profil"
3. Version et "À propos" dans Settings

### UX Reviewer

1. Vérifier CHAQUE écran en light mode et dark mode
2. Vérifier l'accessibilité (VoiceOver, Dynamic Type Large)
3. Vérifier la cohérence visuelle (spacing, couleurs, fonts)
4. Vérifier le flow paywall (UX d'achat, restore)

### QA Engineer

1. Tests `StoreKitManager` (achat, restore, trial expiration)
2. Code review complet de TOUT le code ajouté jusqu'ici
3. Vérifier les conventions CLAUDE.md respectées
4. Build Release + tests

---

## Sprint 5 : App Store ready

> Objectif : tout ce qu'il faut pour cliquer "Submit" dans App Store Connect.

### DevOps Engineer

**Nouveaux fichiers :** `fastlane/metadata/**`, `fastlane/Snapfile`, `fastlane/SnapshotHelper.swift`, `BarPathUITests/BarPathUITests.swift`

1. Metadata App Store (structure LoadSense) :
   ```
   fastlane/metadata/
   ├── copyright.txt          → © 2026 Benjamin Dupin
   ├── primary_category.txt   → Health & Fitness
   ├── en-US/
   │   ├── name.txt           → BarPath - Bar Tracker
   │   ├── subtitle.txt       → Track your barbell path
   │   ├── description.txt    → Description complète
   │   ├── keywords.txt       → barpath,barbell,tracking,squat,deadlift,bench,VBT,velocity,powerlifting,weightlifting
   │   ├── promotional_text.txt
   │   └── release_notes.txt
   ├── fr-FR/                 → Traductions complètes
   └── review_information/
   ```
2. Snapfile : 3 devices × 2 langues × 5 screenshots
3. UI Tests pour screenshot automation
4. Matchfile pour code signing
5. URL privacy policy + URL support

### DevOps Engineer (suite)

1. Mettre à jour `PrivacyInfo.xcprivacy` : Vision, Camera, Photos API declarations
2. Vérifier TOUTES les localisations EN/FR complètes et cohérentes
3. `NSMicrophoneUsageDescription` si audio activé

### QA Engineer — Vérification finale

```bash
# Build Release
xcodebuild build -scheme BarPath -configuration Release -destination generic/platform=iOS

# Tous les tests
xcodebuild test -scheme BarPath -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Screenshots
bundle exec fastlane screenshots

# Dry-run release
bundle exec fastlane release --dry_run
```

1. **Build Release** : 0 erreurs, 0 warnings
2. **Tous les tests passent** : modèles, services, viewmodels, intégration
3. **Code review final** : conventions, dead code, TODOs, sécurité
4. **Screenshots générées** pour tous les devices/langues
5. **Localisations** : aucune clé manquante ou inutilisée
6. **Privacy manifest** : toutes les APIs déclarées

### UX Reviewer — Review finale

1. Screenshot de CHAQUE écran sur iPhone 17 Pro (light + dark)
2. Vérifier le flux complet : Launch → Record → Analyze → Results → Export → History
3. Vérifier Settings, Paywall, Comparison
4. Rapport final avec les derniers ajustements

---

## Post-launch (futur, hors scope)

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
| `BarPath/Views/Record/RecordView.swift` | Permissions caméra + overlay live + erreurs |
| `BarPath/ViewModels/AnalysisViewModel.swift` | Pipeline complet + navigation |
| `BarPath/Views/Result/AnalysisProgressView.swift` | Navigation vers résultats |
| `BarPath/Views/Result/ResultView.swift` | Export + share + frame-by-frame + coaching |
| `BarPath/Services/ExportService.swift` | Fix pixel buffer + timestamp mapping |
| `BarPath/Services/PoseDetectionService.swift` | Bilatéral + Kalman + qualité |
| `BarPath/Services/RepDetectionService.swift` | Validation min/max durée |
| `BarPath/Views/HomeView.swift` | Fix navigation import vidéo |
| `BarPath/Views/SettingsView.swift` | Haptics toggle, review, about |
| `BarPath/PrivacyInfo.xcprivacy` | Déclarations API manquantes |
| `BarPath/Resources/en.lproj/Localizable.strings` | Clés manquantes |
| `BarPath/Resources/fr.lproj/Localizable.strings` | Synchroniser avec EN |

### Nouveaux fichiers :
| Fichier | Description |
|---------|-------------|
| `BarPath/Utils/HapticManager.swift` | Feedback haptique (pattern TempoReps) |
| `BarPath/Utils/DesignTokens.swift` | Couleurs adaptatives, spacing, typography |
| `BarPath/Utils/AccessibilityExtensions.swift` | VoiceOver, Dynamic Type |
| `BarPath/Services/StoreKitManager.swift` | StoreKit 2, Keychain trial |
| `BarPath/Services/OneRMCalculator.swift` | Estimation 1RM VBT |
| `BarPath/Services/CoachingService.swift` | Conseils intelligents localisés |
| `BarPath/Views/PaywallView.swift` | Paywall premium |
| `BarPath/Views/Comparison/ComparisonView.swift` | Comparaison côte-à-côte |
| `BarPath/ViewModels/ComparisonViewModel.swift` | VM comparaison |
| `BarPathUITests/BarPathUITests.swift` | Screenshots automatisés |
| `fastlane/Snapfile` | Config screenshots |
| `fastlane/SnapshotHelper.swift` | Helper Fastlane |
| `fastlane/Matchfile` | Code signing |
| `fastlane/metadata/**` | Metadata App Store EN/FR |
| `Configuration.storekit` | Config StoreKit test |
