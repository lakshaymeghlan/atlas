# Canopy (repo: Atlas) — Phase 1 prototype

Native iOS app that carries a person through a job transition. Upload a CV once,
tap through the rest.

The journey: **Welcome → what brings you here → bring your experience in →
analysing (the river) → 7-step preferences wizard → profile review → Home**
(Home · Explore · Journey · Profile tabs). It's a **client-side prototype** —
sign-in is stubbed, CV parsing is mocked, and the jobs/pipeline data is sample
data (see [DECISIONS.md](DECISIONS.md)). Two real Supabase edge functions exist
but aren't wired to the app yet — see [supabase/functions](supabase/functions/README.md).

## Requirements

- macOS with **full Xcode 15+** (iOS 17 SDK). Command Line Tools alone can't
  build a SwiftUI app.
- [XcodeGen](https://github.com/yonyz/XcodeGen): `brew install xcodegen`

## Run

```sh
xcodegen generate      # writes Atlas.xcodeproj (and Info.plist) from project.yml
open Atlas.xcodeproj   # then ⌘R on any iPhone simulator (iOS 17+)
```

No secrets, no accounts, no network needed — it runs entirely offline.

## Layout

```
Atlas/
  App/        AtlasApp, AppRouter (journey state machine), Journey, Config, RootView
  Design/     Tokens (colour/type/space/motion), Components/, System/, River/
  Features/   Welcome, UploadCV, Analysing, Preferences, ConfirmProfile,
              Home (tab shell + dashboard), Jobs, Journey, Profile
  Core/       Auth/, Profile/ (stores + models + preferences), Parsing/ (mock parser)
  Resources/  Assets.xcassets, Fonts/
AtlasTests/   CV decoder, journey restoration, file validation
```

## The River

`RiverCanvas` is the full-screen moving water on the Analysing screen — drifting
waves, the CV dissolving into falling lines of text, and an optional Metal ripple
behind `Config.useShaders`. It respects Reduce Motion (freezes to a static
gradient), as do the screen transitions. Preview it in isolation via the
`"River"` preview. Onboarding progress is the minimal `StageProgress` segments in
`OnboardingScaffold`, not a river.

## What's stubbed (and where the backend plugs in)

| Real thing | Prototype stand-in | File |
|---|---|---|
| Supabase OAuth | session fabricated on tap | `Core/Auth/AuthStore.swift` |
| `parse-cv` edge function | delay + canned JSON | `Core/Parsing/MockCVParser.swift` |
| GitHub / LinkedIn connectors | canned stats + repos | `Core/Parsing/MockIntegrations.swift` |
| Postgres + Storage | `UserDefaults` JSON | `Core/Profile/ProfileStore.swift` |
| Matching engine + pipeline | sample matches / applications | `Features/Jobs/JobMatch.swift` |

The mock parser returns the exact JSON shape the real edge function will, so
`CVParseResult` (and its tests) carry straight over. Jobs data is in-memory only
— it resets on relaunch; the profile does not.

## Demo hooks

`Config.demoMode` is **on**, so tapping the upload zone attaches a sample CV
instead of opening the Files picker (hosted previews can't reach a filesystem).
Flip it off to get the real picker, inline file validation, and the mock parser's
filename branches:

- normal name → success (canned profile) after ~1.8s
- name contains `scan` / `image` / `photo` → the clean **failure** state
- name contains `slow` → the **>12s** "still working" copy

Enable **Reduce Motion** (Settings › Accessibility, or the simulator's setting)
to see the river collapse to a static gradient and transitions to plain fades.

## Tests

`⌘U` runs the unit tests: CV JSON decoder (incl. malformed / missing-field),
`JourneyState` restoration (including resuming mid-wizard), and file validation.

## Quality notes

- Light mode only (dark deferred to Phase 2).
- Dynamic Type supported and capped at XXL so layouts hold.
- No force unwraps in app code; `os.Logger` per feature; no `print`.
- `Features/RolePreferences` is parked, not reachable — the wizard replaced it.
