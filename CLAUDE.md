# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation Maintenance (MANDATORY)

**This file MUST always be kept up to date:**
- When a feature is added, modified, or removed: update relevant sections
- When a new file/service/model is created: add it to the Architecture section
- When algorithms change: update relevant documentation
- When new dependencies are added: document them
- When test files are added: update the Testing section
- When new generated files or tooling outputs appear: update `.gitignore`

**Rule: No PR/commit should change the codebase structure without updating this file.**

## Project Overview

**BarPath** is an iOS barbell path tracking app that uses the Vision framework to detect wrist positions via human body pose estimation and render the barbell trajectory in real time. It helps lifters analyze their bar path for squats, bench press, deadlifts, and other barbell movements.

**Business Model:** One-time purchase (~4.99-6.99 EUR), no subscription, no ads.

**Target:** iOS 26.0+ | Swift 6 | SwiftUI 100%

**Key Principles:**
- **Privacy First**: All video processing happens on-device, no external servers, no data collection
- **Zero Dependencies**: Only Apple frameworks (Vision, AVFoundation, SwiftUI)
- **Scientific Accuracy**: Velocity, displacement, and drift calculations based on proper biomechanical definitions
- **Intuitive Design**: Record, analyze, review - three-step workflow with no onboarding needed

**Out of Scope (for now):**
- Apple Watch app
- Cloud sync / sharing
- Social features

---

## Mandatory Rules

### Documentation

- **CLAUDE.md MUST stay in sync** with code structure
- Update after adding/removing/moving files in Models/, Services/, ViewModels/, Views/

### Code Quality

- **Zero warnings** - All build warnings fixed before task completion
- **Zero bugs backlog** - Bugs fixed immediately
- **No dead code** - Remove unused code, no commented blocks
- **No TODO/FIXME** - Resolve before committing

### Testing

- **ALL features MUST have unit tests**
- **Coverage target: 80%+**
- Use Swift Testing framework (`@Test` macro)
- Run tests before every commit

### Memory Management

For async data fetching:

```swift
private var fetchTask: Task<Void, Never>?

deinit {
    fetchTask?.cancel()
}

func fetchData() async {
    fetchTask?.cancel()
    fetchTask = Task {
        // ... fetch logic
        if Task.isCancelled { return }
        // ... process
    }
}
```

---

## Swift Standards

### Required Patterns

```swift
// Observable (Swift 6 - NOT ObservableObject)
@Observable
final class RecordViewModel { }

// Main thread
@MainActor
final class VideoProcessorService { }

// Optional handling - ALWAYS guard let
guard let value = optionalValue else { return }

// NEVER force unwrap (except in tests)
// BAD: value!
// GOOD: guard let value = value else { return }

// Async/await - NEVER completion handlers
func processVideo() async throws -> BarPathAnalysis { }
```

### Localization

- **ALL user-facing strings** in `Localizable.strings`
- **EN primary, FR secondary**
- Use `NSLocalizedString("key", comment: "description")`
- Keys alphabetically ordered

---

## Project Configuration

**Bundle Identifier:** `app.barpath`
**Team ID:** `767SX34A7Z`
**Marketing Version:** 1.0
**Minimum iOS:** 26.0+
**Deployment Target:** iOS 26.0

**Privacy & Compliance:**
- `PrivacyInfo.xcprivacy` - Privacy Manifest (required for App Store)
- Camera used for recording but video is processed entirely on-device
- No tracking, no external data transmission
- UserDefaults only for local persistence

**License:** Proprietary - All Rights Reserved (see LICENSE file)

---

## Project Structure

```
BarPath/
├── BarPathApp.swift                    # @main entry point
├── Models/
│   ├── BarPathPoint.swift             # Single tracked point (x, y, timestamp, confidence)
│   ├── LiftType.swift                 # Enum: squat, benchPress, deadlift, overheadPress, clean, snatch, row, other
│   ├── RepSegment.swift               # Individual rep with velocities, displacement, drift, duration
│   ├── AnalysisMetrics.swift          # Aggregate metrics across all reps (peak/avg velocity, drift, consistency)
│   ├── BarPathAnalysis.swift          # Complete analysis result (points, reps, metrics, video URL)
│   ├── CalibrationData.swift          # Normalized-to-meters conversion (plate size, user height, manual)
│   ├── RecentAnalysis.swift           # Lightweight summary for history lists
│   └── AppSettings.swift              # User settings (lift type, FPS, overlays, path color)
├── Services/
│   ├── PoseDetectionService.swift     # Vision framework wrist pose detection
│   ├── BarPathAnalyzer.swift          # Smoothing, velocity calculation, drift analysis
│   ├── RepDetectionService.swift      # Rep detection from smoothed points (to be created)
│   ├── VideoProcessorService.swift    # AVFoundation frame extraction (to be created)
│   └── DataStore.swift                # UserDefaults persistence (to be created)
├── Services/Protocols/
│   ├── PoseDetecting.swift            # Protocol for PoseDetectionService
│   ├── VideoProcessing.swift          # Protocol for VideoProcessorService
│   ├── BarPathAnalyzing.swift         # Protocol for BarPathAnalyzer
│   └── DataStoring.swift              # Protocol for DataStore
├── ViewModels/
│   ├── RecordViewModel.swift          # Camera recording and live pose detection (to be created)
│   ├── ResultViewModel.swift          # Analysis results display and export (to be created)
│   ├── HistoryViewModel.swift         # History list management (to be created)
│   └── SettingsViewModel.swift        # Settings management (to be created)
├── Views/
│   ├── Record/
│   │   └── RecordView.swift           # Camera recording screen with live overlay (to be created)
│   ├── Result/
│   │   └── ResultView.swift           # Analysis results with path visualization (to be created)
│   ├── History/
│   │   └── HistoryView.swift          # Past analyses list (to be created)
│   └── Components/
│       ├── BarPathOverlayView.swift   # Path drawing overlay on video (to be created)
│       ├── MetricCardView.swift       # Individual metric display card (to be created)
│       ├── RepComparisonView.swift    # Side-by-side rep comparison (to be created)
│       └── VelocityGradientView.swift # Velocity color gradient legend (to be created)
├── Utils/
│   ├── Constants.swift                # App-wide constants (thresholds, limits)
│   ├── Extensions.swift               # Date, Double, TimeInterval, Color extensions
│   └── Formatters.swift               # Centralized formatting (velocity, displacement, drift)
├── Resources/
│   ├── en.lproj/
│   │   └── Localizable.strings        # English translations
│   └── fr.lproj/
│       └── Localizable.strings        # French translations
└── PrivacyInfo.xcprivacy              # Privacy manifest

BarPathTests/
├── Models/
│   ├── BarPathPointTests.swift        # (to be created)
│   ├── LiftTypeTests.swift            # (to be created)
│   ├── RepSegmentTests.swift          # (to be created)
│   ├── AnalysisMetricsTests.swift     # (to be created)
│   ├── BarPathAnalysisTests.swift     # (to be created)
│   ├── CalibrationDataTests.swift     # (to be created)
│   └── AppSettingsTests.swift         # (to be created)
├── Services/
│   ├── BarPathAnalyzerTests.swift     # (to be created)
│   └── RepDetectionServiceTests.swift # (to be created)
├── ViewModels/
│   ├── RecordViewModelTests.swift     # (to be created)
│   ├── ResultViewModelTests.swift     # (to be created)
│   └── HistoryViewModelTests.swift    # (to be created)
└── Mocks/
    ├── MockPoseDetectionService.swift # (to be created)
    ├── MockDataStore.swift            # (to be created)
    └── MockVideoProcessor.swift       # (to be created)

BarPathUITests/
├── BarPathUITests.swift               # (to be created)
└── BarPathUITestsLaunchTests.swift    # (to be created)

Gemfile                                # Bundler dependencies
fastlane/
├── Appfile                            # App metadata (bundle ID, team)
├── Fastfile                           # Lanes: test, beta, release, release_quick
└── metadata/                          # App Store metadata
    ├── copyright.txt                  # Copyright notice
    ├── primary_category.txt           # App Store category
    ├── en-US/                         # English metadata
    │   ├── name.txt                   # App name (30 chars)
    │   ├── subtitle.txt               # Subtitle (30 chars)
    │   ├── description.txt            # Full description (4000 chars)
    │   ├── keywords.txt               # Keywords (100 chars)
    │   ├── promotional_text.txt       # Promotional text (170 chars)
    │   ├── release_notes.txt          # What's new
    │   └── privacy_url.txt            # Privacy policy URL
    ├── fr-FR/                         # French metadata
    │   ├── name.txt
    │   ├── subtitle.txt
    │   ├── description.txt
    │   ├── keywords.txt
    │   ├── promotional_text.txt
    │   └── release_notes.txt
    └── review_information/
        └── notes.txt                  # App Review instructions
```

---

## Key Algorithms

### Pose Detection (PoseDetectionService)
- Uses `VNDetectHumanBodyPoseRequest` to detect human body poses
- Extracts wrist joint positions (prefers right wrist, falls back to left)
- Filters by minimum confidence threshold (0.3)
- Flips Y coordinate from Vision's bottom-left origin to top-left

### Path Smoothing (BarPathAnalyzer)
- Moving average with configurable window size (default 5)
- Preserves timestamps and confidence values
- Reduces noise from frame-to-frame detection jitter

### Velocity Calculation (BarPathAnalyzer)
- Frame-to-frame Euclidean distance / time delta
- Units: normalized coordinates per second (or m/s with calibration)

### Horizontal Drift (BarPathAnalyzer)
- Maximum absolute horizontal deviation from the starting X position within a rep

### Rep Consistency (AnalysisMetrics)
- Coefficient of variation of vertical displacement and duration
- Score from 0 (highly variable) to 1 (perfectly consistent)

---

## Persistence

Using **UserDefaults** for:
- Recent analyses (lightweight summaries, max 20)
- User settings (lift type, FPS, overlays)
- Calibration data

Full analysis data stored as encoded JSON in app documents directory.

---

## Build & Test

### Local Development

```bash
# Build simulator
xcodebuild -scheme BarPath -destination 'platform=iOS Simulator,name=iPhone 17'

# Build device
xcodebuild -scheme BarPath -destination generic/platform=iOS

# Run tests
xcodebuild test -scheme BarPath -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Fastlane

```bash
bundle exec fastlane test          # Run all unit tests
bundle exec fastlane beta          # TestFlight
bundle exec fastlane release       # Full App Store
bundle exec fastlane release_quick # App Store without screenshots
```

---

## Code Quality Standards

### Clean Code Principles (MANDATORY)

- **SOLID principles**: Single responsibility, Open/closed, Liskov substitution, Interface segregation, Dependency inversion
- **DRY (Don't Repeat Yourself)**: Extract common logic into reusable functions/extensions
- **KISS (Keep It Simple, Stupid)**: Prefer simple, readable solutions over clever ones
- **Meaningful names**: Variables, functions, and types must have clear, descriptive names
- **Small functions**: Each function should do one thing well (< 30 lines ideally)
- **Small views**: Keep SwiftUI views focused (< 200 lines ideally), extract components

### Code Hygiene (MANDATORY)

- **Zero warnings**: Fix ALL build warnings before finishing any task
- **No dead code**: Delete unused functions, variables, imports, and commented-out code
- **No TODO/FIXME left behind**: Either fix them or create tracked issues
- **Consistent formatting**: Follow Swift standard formatting conventions

### Bug Policy (MANDATORY)

**Zero Bug Backlog:** When a bug is identified during any task:
1. Fix it immediately (if within scope)
2. If outside current scope, fix it anyway if it's Critical
3. Never "track" bugs for later - there is no bug backlog
4. Run tests after every fix

### Swift Standards

- **Framework:** 100% SwiftUI (no UIKit unless absolutely necessary)
- **Concurrency:** Swift 6 `async/await` and Actors only - no completion handlers
- **State:** `@Observable` for ViewModels (Swift 6 Observation framework)
- **Structs over classes** when possible
- **Guard let** for early exit - no force unwrapping (`!`) except in tests
- **Prefer `let` over `var`** when possible
- **Use `@MainActor`** on classes that need main thread execution

### Internationalization

- **IMPORTANT**: All user-facing strings MUST be in `Localizable.strings`
- Use `NSLocalizedString("key", comment: "description")`
- Support English (primary) and French (secondary)
- Never hardcode strings in Swift files

---

## Testing (MANDATORY)

### Test Coverage Requirements

- **ALL features must have unit tests** - no exceptions
- **All Services** must have comprehensive unit tests
- **All Calculators** (BarPathAnalyzer, RepDetection) must have comprehensive tests
- **All ViewModels** must have unit tests for their business logic
- **All utility functions** must be tested

### Test Standards

- Prefer **Swift Testing** (`@Test` macro) over XCTest
- Use mock data for Vision/Camera in tests
- **Test edge cases**: no data, partial data, invalid values, boundary conditions
- **Update tests when features change**: If a feature evolves, add or update tests
- **Run tests after every change**: Always verify tests pass before considering work complete

---

## Workflow

**Before any code change:**
1. Read and understand existing code
2. Check for similar patterns in the codebase

**After any code change:**
1. Build for simulator - Verify compilation (zero warnings)
2. Build for device - Verify device compilation
3. Run tests - Verify all tests pass
4. Remove any dead code introduced
5. **Update CLAUDE.md** if structure changed

**IMPORTANT:**
- Both simulator AND device builds must succeed before considering a task complete
- Tests are mandatory after every change, without exception

---

## Fastlane Configuration

**Prerequisites:** `bundle install` (Gemfile includes Fastlane)

**Configuration files:**
| File | Purpose |
|------|---------|
| `fastlane/Appfile` | Bundle identifier, team ID, API key reference |
| `fastlane/Fastfile` | Lanes: test, screenshots, beta, release, release_quick, metadata |
| `fastlane/asc_api_key.json` | App Store Connect API credentials (gitignored) |
| `fastlane/metadata/` | App Store metadata (EN-US, FR-FR) |

**Lanes:**
```bash
bundle exec fastlane screenshots         # Generate screenshots
bundle exec fastlane beta                # Build + TestFlight
bundle exec fastlane release             # Build + App Store
bundle exec fastlane release_quick       # App Store without screenshots
bundle exec fastlane metadata            # Upload metadata only
bundle exec fastlane upload_screenshots  # Upload screenshots only
```

**First-time setup:**
1. Create API Key at https://appstoreconnect.apple.com/access/api
2. Create `fastlane/asc_api_key.json` with your credentials
3. Initialize Match: `bundle exec fastlane match appstore`

---

## Release Workflow

```
1. /verify        - Build, test, quality check
2. /push          - Safe push to main with builds + tests
3. /release       - App Store deployment
```

---

## App Store

**Bundle ID:** app.barpath | **Category:** Health & Fitness | **Languages:** EN (primary), FR

---

## Active Technologies

- Swift 6, iOS 26.0+, SwiftUI, Vision, AVFoundation
- UserDefaults for persistence
- No third-party dependencies
