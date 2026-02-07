# BarPath - Guide de Soumission App Store

## ✅ Checklist Pré-Soumission

### Complété
- [x] Code finalisé (5 sprints complets)
- [x] Release build vérifié
- [x] Metadata App Store (EN + FR)
- [x] Privacy manifest (PrivacyInfo.xcprivacy)
- [x] StoreKit configuration
- [x] Localization 100% (137 strings)
- [x] Privacy policy créée (privacy-policy.html)

### À Faire Manuellement

#### 1. App Icon (REQUIS)
L'app a besoin d'une icône 1024×1024 pixels.

**Option A - Designer vous-même:**
```bash
# Créer l'icône dans un éditeur graphique
# Format: PNG, 1024×1024px, sans transparence
# Style suggéré:
# - Couleur: Bleu (#007AFF) ou orange
# - Symbole: Trajectoire de barre stylisée
# - Texte: "BP" ou icône abstraite
```

**Option B - Utiliser un outil:**
- Figma / Sketch / Canva
- App Icon Generator en ligne
- Midjourney / DALL-E pour génération AI

**Ajouter à Xcode:**
1. Ouvrir `BarPath.xcodeproj` dans Xcode
2. Naviguer vers `BarPath/Assets.xcassets/AppIcon`
3. Glisser-déposer votre icône 1024×1024

#### 2. Héberger la Privacy Policy

**Option A - GitHub Pages (gratuit):**
```bash
# Créer un repo public sur GitHub
# Ajouter privacy-policy.html
# Activer GitHub Pages dans Settings
# URL finale: https://[username].github.io/barpath-privacy/privacy-policy.html
```

**Option B - Hébergement web:**
- Héberger privacy-policy.html sur barpath.app/privacy
- Ou utiliser Netlify/Vercel (gratuit)

**Mettre à jour l'URL:**
```bash
# Éditer le fichier
nano fastlane/metadata/en-US/privacy_url.txt
# Remplacer par votre vraie URL
```

---

## 🚀 Étapes de Soumission

### 1. Préparer le Compte Apple Developer

**Inscription (si pas déjà fait):**
- Aller sur https://developer.apple.com
- S'inscrire au programme (99$/an)
- Attendre validation (1-2 jours)

**Créer l'App dans App Store Connect:**
1. https://appstoreconnect.apple.com
2. "My Apps" → "+" → "New App"
3. Plateformes: iOS
4. Bundle ID: `app.barpath`
5. SKU: `barpath-ios`
6. Nom: "BarPath"

### 2. Configurer In-App Purchase

**Dans App Store Connect:**
1. Votre App → "In-App Purchases"
2. "+" → "Non-Consumable"
3. Product ID: `app.barpath.lifetime`
4. Prix: €6.99 (Tier 6)
5. Nom: "BarPath Lifetime"
6. Description: "Unlock unlimited analyses, comparison, and coaching"
7. Submit for review

### 3. Certificates & Provisioning

**Dans Xcode:**
```bash
# Ouvrir le projet
open BarPath.xcodeproj

# Dans Xcode:
# 1. Sélectionner le projet "BarPath"
# 2. Target "BarPath" → Signing & Capabilities
# 3. Team: Sélectionner votre team (Benjamin Dupin)
# 4. Cocher "Automatically manage signing"
# 5. Bundle Identifier: app.barpath (déjà configuré)
```

**Ou via Fastlane Match:**
```bash
# Initialiser Match (première fois)
bundle exec fastlane match init

# Créer les certificats
bundle exec fastlane match appstore
```

### 4. Build & Archive

**Option A - Via Xcode (recommandé pour la 1ère fois):**
```
1. Product → Scheme → BarPath
2. Product → Destination → Any iOS Device (arm64)
3. Product → Archive
4. Attendre la compilation (~2-3 min)
5. Dans Organizer: "Distribute App"
6. "App Store Connect" → Next
7. "Upload" → Next
8. Signer avec certificats → Upload
```

**Option B - Via Fastlane:**
```bash
# TestFlight (beta testing)
bundle exec fastlane beta

# Production (App Store)
bundle exec fastlane release
```

### 5. Remplir App Store Connect

**Aller sur App Store Connect → Votre App:**

**App Information:**
- Catégorie principale: Health & Fitness
- Catégorie secondaire: Sports
- Privacy Policy URL: [votre URL]
- Subtitle: "Track your barbell path"

**Pricing and Availability:**
- Price: Gratuit (free download)
- Availability: Tous les pays

**App Privacy:**
- Data Collection: None
- Cocher: "No, we do not collect data from this app"

**Version Information:**
- Version: 1.0
- Copyright: © 2026 Benjamin Dupin
- Description: (copier depuis `fastlane/metadata/en-US/description.txt`)
- Keywords: (copier depuis `fastlane/metadata/en-US/keywords.txt`)
- Promotional Text: (copier depuis `fastlane/metadata/en-US/promotional_text.txt`)

**Screenshots (REQUIS):**
```bash
# Générer automatiquement via Fastlane
bundle exec fastlane screenshots

# Ou manuellement:
# 1. Lancer app dans Simulator (iPhone 17 Pro)
# 2. Naviguer vers chaque écran
# 3. Cmd+S pour screenshot
# 4. Uploader dans App Store Connect
```

Écrans à capturer:
1. Home screen avec recent analyses
2. Record screen avec caméra preview
3. Analysis progress
4. Results avec bar path overlay
5. Metrics détaillés
6. Comparison view (optionnel)

### 6. Soumettre pour Review

1. **Build:** Sélectionner le build uploadé
2. **Export Compliance:** "No" (pas de cryptographie)
3. **Advertising Identifier:** "No" (pas de tracking)
4. **Version Release:** "Automatically release"
5. **Review Notes:** (optionnel, ou copier depuis review_information/notes.txt)
6. **Submit for Review** → ✅

---

## ⏱️ Délais Attendus

- **Upload build:** 5-10 min
- **Processing:** 10-30 min
- **Review:** 1-3 jours (moyenne: 24h)
- **Si rejeté:** Corrections + resoumission

---

## 🆘 Troubleshooting

### Erreur "Missing Bundle Identifier"
→ Vérifier que Bundle ID = `app.barpath` dans Xcode

### Erreur "Missing Privacy Descriptions"
→ Déjà configuré dans project.pbxproj (Camera + Photos)

### Erreur "Invalid Product ID"
→ Créer l'IAP dans App Store Connect d'abord

### Build Failed lors d'Archive
→ S'assurer d'avoir sélectionné "Any iOS Device" et non un simulator

### "No accounts with App Store Connect access"
→ Ajouter votre Apple ID dans Xcode → Preferences → Accounts

---

## 📞 Support

**Questions sur le code:**
- Voir `CLAUDE.md` pour architecture
- Voir `SPRINT[1-5]_COMPLETION.md` pour détails

**Questions App Store:**
- https://developer.apple.com/support/
- https://developer.apple.com/app-store/review/guidelines/

---

## 🎉 Après Validation

**L'app est live!**
1. Partager sur réseaux sociaux
2. Demander reviews aux premiers utilisateurs
3. Monitorer Analytics dans App Store Connect
4. Répondre aux reviews

**Updates futures:**
```bash
# Incrémenter version dans Xcode
# Marketing Version: 1.1
# Build: 2

# Développer features
# Tester, build, upload

# Soumettre update dans App Store Connect
```

---

**Bonne chance! 🚀**

L'app est prête. Il ne reste que ces étapes administratives et vous êtes live sur l'App Store.
