# Atlas Phase 1 — build audit

_Prototype delivered 2026-07-27. Client-side only, no backend (per direction)._

---

## 1. What was built

A complete, running iOS prototype of the Atlas front door. It **builds clean
for the iOS Simulator with zero code warnings**, launches, and renders. The
whole journey works end to end with local stubs standing in for the backend.
 
**The journey** (all screens built, wired through a state machine):

| Screen | State | What works |
|---|---|---|
| S01 Welcome | `welcome` | River-as-promise, cold-start fade-up, LinkedIn/GitHub buttons, stubbed sign-in |
| S02 Career path | `careerPath` | Two cards; "looking" navigates, "employed" shows inline "coming soon" |
| S03 Upload CV | `uploadCV` | Drop zone → `.fileImporter` (PDF/DOCX), inline validation, file row, disabled LinkedIn import |
| S04 Analysing | `analysing` | Full-screen river, 2.5s minimum hold, >12s copy, clean failure state |
| S05 Confirm profile | `confirmProfile` | 4 section cards, low-confidence blue dots + top-sort, "Add …" for nulls, edit sheets (add/delete) |
| S06 Home | `home` | What's-coming copy, read-only profile summary, sign out |

**The River** (the signature) is fully implemented per spec:
- `Current` — the progress river: sine curve, glowing travelled portion, breathing
  current node, 12s phase drift, segment-completes-into-node animation + success
  haptic on each stage entry.
- `RiverCanvas` — the Analysing screen: three drifting waves, the CV dissolving
  into falling "lines of text" (fixed particle pool), cycling status line, and a
  `River.metal` distortion ripple (gated behind `Config.useShaders`).
- Both fully honour **Reduce Motion** (static gradients, plain fades).

**Design system** — exact spec values: `Palette`, scalable type roles (Dynamic
Type up to XXL), space/radius/shadow/motion tokens, all in `Tokens.swift`.
Components: `AtlasButton`, `AtlasCard`, `Eyebrow`, `ChipView`, `FlowLayout`,
`OnboardingScaffold`, plus a `ComponentGallery` preview.

**Quality floor met:** no force-unwraps in app code, `os.Logger` per feature (no
`print`), accessibility labels/traits throughout, VoiceOver announcements on the
river, restoration that never dumps you back to Welcome after a force-quit.

**Tests:** CV JSON decoder (valid / malformed / missing-field), `JourneyState`
restoration logic, and file validation. (Run with ⌘U.)

**Verified:** `BUILD SUCCEEDED` for `iphonesimulator`; installed and launched on
an iPhone 17 simulator — Welcome + River render correctly.

---

## 2. What's a stub (and where the real thing plugs in)

Per your "no database for now" direction, the backend is faked locally. Each seam
is a clean drop-in point:

| Real thing (deferred) | Prototype stand-in | File to change |
|---|---|---|
| Supabase OAuth (LinkedIn/GitHub) | fake user on tap | `Core/Auth/AuthStore.swift` |
| `parse-cv` edge function (Anthropic) | 1.8s delay + canned JSON | `Core/Parsing/MockCVParser.swift` |
| Postgres + Storage | `UserDefaults` JSON | `Core/Profile/ProfileStore.swift` |

The mock parser returns the **exact JSON shape** the real edge function will, and
it's decoded through the real `CVParseResult` decoder — so the decoder, its
tests, and the whole confirm screen carry straight over. The Supabase SPM
dependency was removed from `project.yml` so the app builds offline; it goes back
when the backend lands.

---

## 3. What you need to do

### To run it yourself
```sh
brew install xcodegen          # if you don't have it
cd atlas
xcodegen generate              # writes Atlas.xcodeproj (gitignored)
open Atlas.xcodeproj           # pick an iPhone sim (iOS 17+), press ⌘R
```
No accounts, secrets, or network needed — it runs fully offline.

**First-run gotchas on this Mac (I already handled the first one for you):**
- **Metal toolchain** — the River shader needs it. I ran
  `xcodebuild -downloadComponent MetalToolchain` (≈688 MB), so it's installed now.
  On a fresh machine Xcode will prompt for it, or run that command.
- **"CoreSimulator is out of date"** — your CoreSimulator (1051.54.0) is a hair
  behind what this Xcode expects (1051.55.0). `xcodebuild` disabled its own
  simulator support because of it, but `simctl` still worked and the app ran.
  **Reboot the Mac** (or update Xcode / run it once through the GUI) to clear it
  fully. It does not affect the code.
- **Signing** — simulator needs none. For a physical device, set
  `DEVELOPMENT_TEAM` in `project.yml` (currently blank).

### Product / assets decisions (yours or the client's)
- **Provider glyphs** are monogram placeholders (`ProviderMark.swift`) — drop in
  licensed LinkedIn/GitHub marks before release.
- **App icon** is an empty placeholder — add real artwork in `Assets.xcassets`.
- **General Sans font** isn't bundled (headlines currently render in SF Pro
  Display, the approved fallback). To activate: drop `GeneralSans-Bold.otf` into
  `Atlas/Resources/Fonts/`, add it to the target + `UIAppFonts` in `project.yml`.
  One-line change, no code (see `DECISIONS.md`).
- Confirm the **LinkedIn limitation** framing with the client: LinkedIn login
  returns name/email/photo only — the CV is the profile. The "Import from
  LinkedIn" button is intentionally visible-but-disabled with an honest caption.

### Phase 2 backlog (when you go past prototype)
1. **Sign in with Apple** — App Store Guideline 4.8 makes it mandatory once you
   offer third-party login. Do this first; ~an afternoon.
2. **Real Supabase backend** — project, schema + RLS, private `cvs` storage
   bucket, and the `parse-cv` Deno edge function calling Anthropic (keeps the API
   key off-device). This is the original spec's Steps 4 & 8.
3. **Dark mode** — currently locked off with `.preferredColorScheme(.light)`.
4. GitHub-languages-as-skills bonus, and swapping the LinkedIn button live once
   OIDC is wired.

---

## 4. Known simplifications (deliberate)

- Screen transitions animate "downstream" in both directions (no back-specific
  reverse) — the state machine doesn't track direction. Cosmetic.
- Restoration derives the resume point from persisted data; a force-quit during
  *manual entry* with nothing typed resumes at Upload rather than Confirm.
- Edit sheets autosave on every keystroke (fine at prototype data sizes).
- Line-height is approximated with SwiftUI `lineSpacing` (no direct API).

Everything above is noted inline or in `DECISIONS.md`.
