# App Icon - Instructions

## Requis
- Format: PNG
- Taille: 1024 × 1024 pixels
- Sans transparence (alpha channel)
- Couleur: RGB (pas CMYK)

## Suggestions de Design

### Style 1: Trajectoire Minimaliste
- Fond: Dégradé bleu (#007AFF → #0051D5)
- Icône: Ligne courbe blanche représentant une trajectoire de barre
- Style: Clean, moderne, iOS-like

### Style 2: Lettre BP
- Fond: Orange/Bleu
- Texte: "BP" en bold, blanc
- Sous-titre optionnel: "Path" en plus petit

### Style 3: Graphique Abstrait
- Fond: Noir/Gris foncé
- Élément: Graphique stylisé de bar path
- Couleur accent: Orange/Vert pour montrer le mouvement

## Outils Recommandés

**En ligne (gratuit):**
- Canva: https://www.canva.com
- AppIconGen: https://appicon.co
- Figma: https://www.figma.com

**Desktop:**
- Sketch (Mac)
- Affinity Designer
- Adobe Illustrator

**AI Generation:**
- DALL-E / Midjourney
- Prompt: "Minimalist app icon for barbell tracking app, blue gradient background, white curved line showing barbell path, modern iOS style, 1024x1024"

## Ajout à Xcode

1. Ouvrir `BarPath.xcodeproj`
2. Naviguer vers `Assets.xcassets`
3. Cliquer sur `AppIcon`
4. Glisser-déposer votre PNG 1024×1024 dans le slot "App Store iOS 1024pt"
5. Xcode générera automatiquement toutes les tailles nécessaires

## Vérification

```bash
# L'icône doit apparaître dans:
ls -la BarPath/Assets.xcassets/AppIcon.appiconset/

# Devrait contenir:
# - Contents.json
# - AppIcon-1024.png (votre icône)
```

## Alternative Rapide

Si vous voulez juste tester la soumission, créez une icône placeholder temporaire:
1. Créer une image 1024×1024 avec fond uni bleu
2. Ajouter texte "BP" au centre
3. L'uploader dans Xcode
4. ⚠️ Remplacer par une vraie icône professionnelle avant le lancement public

