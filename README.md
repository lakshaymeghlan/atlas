# Atlas — Phase 1 (prototype)

Native iOS app that carries a person through a job transition. You are the raft,
Atlas is the current. Upload a CV once, tap through the rest.

This repo is the **front door**: Welcome → career path → upload CV → analysing
(the river) → confirm profile → Home stub. It's a **client-side prototype** —
no backend yet. Sign-in is stubbed and CV parsing is mocked (see
[DECISIONS.md](DECISIONS.md)).

## Requirements

- macOS with **full Xcode 15+** (iOS 17 SDK). Command Line Tools alone can't
  build a SwiftUI app.
- [XcodeGen](https://github.com/yonyz/XcodeGen): `brew install xcodegen`

## Run

```sh
xcodegen generate      # writes Atlas.xcodeproj from project.yml
open Atlas.xcodeproj    # then ⌘R on an iPhone 15 simulator (iOS 17+)
```

No secrets, no accounts, no network needed — it runs entirely offline.

## Layout

```
Atlas/
  App/        AtlasApp, AppRouter (journey state machine), Config, RootView
  Design/     Tokens (colour/type/space/motion), Components/, River/
  Features/   Welcome, CareerPath, UploadCV, Analysing, ConfirmProfile, Home
  Core/       Auth/, Profile/ (stores + models), Parsing/ (mock CV parser)
  Resources/  Assets.xcassets, Fonts/
AtlasTests/   decoder, journey restoration, file validation
```

## The River

The signature. `Current` is the persistent progress river at the top of every
onboarding screen; `RiverCanvas` is the full-screen moving water on the
Analysing screen. Both respect Reduce Motion (they freeze to static gradients).
Preview them in isolation — `Current_Previews`, `RiverCanvas_Previews`.

## What's stubbed (and where the backend plugs in)

| Real thing | Prototype stand-in | File |
|---|---|---|
| Supabase OAuth | fake user on tap | `Core/Auth/AuthStore.swift` |
| `parse-cv` edge function | delay + canned JSON | `Core/Parsing/MockCVParser.swift` |
| Postgres + Storage | `UserDefaults` JSON | `Core/Profile/ProfileStore.swift` |

The mock parser returns the exact JSON shape the real edge function will, so
`CVParseResult` (and its tests) carry straight over.
