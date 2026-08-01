# Atlas — Onboarding Design Report

**Date:** 2026-08-01
**Scope:** Phase 1 onboarding (Welcome → Career Path → Upload CV → Analysing → Confirm Profile → Home)
**Status:** Working prototype on iOS Simulator. Latest design pass **not yet committed** (held pending sign-off).

---

## 1. Summary

The onboarding front door has been redesigned into a single, cohesive, premium‑minimal
experience. The screen a first‑time visitor sees now communicates **what Atlas does** and
**how**, feels **warm and alive** rather than blank, and stays **clean and editorial**
throughout. The same visual language now runs across every onboarding screen, and the
button system is unified so nothing looks out of place.

Two headline changes in this pass:

1. **A warm "sunrise" sky** (soft sun glow + gentle drifting clouds that dissolve into the
   ivory) sits at the top of every screen — the app's signature atmosphere.
2. **One clean button system** across the whole app — a solid ink primary and a
   white + hairline secondary — replacing the earlier glassy/washed buttons.

The literal "river + paper boat" motif was explored and then **retired** in favour of the
calmer, more legible sky direction (see §6).

---

## 2. What the app looks like now

**Welcome (S01)**
- Warm ivory background (`#FCFBF8`) with a soft **sunrise sky** at the top: a warm glow
  (the sun, upper‑right) and a few soft clouds drifting slowly, blending into the ivory.
- `ATLAS` wordmark (tracked, upper‑left).
- Editorial hero: **"Your career, without the chaos."**
- One line of value: *"Upload your CV once. Atlas builds your profile and connects you to
  work that fits."*
- Two clean sign‑in buttons: **Continue with LinkedIn** (blue mark) and **Continue with
  GitHub**, with a soft press animation + haptic.
- Trust line with a lock: *"We only read what you approve."*

**Career Path / Upload CV / Confirm Profile (S02–S05)**
- Same warm sky (subtler) + ivory background.
- A **minimal 3‑segment progress indicator** at the top (fills as the user advances) — this
  replaced the animated boat/river progress bar.
- Clean white cards, editorial headlines, and the unified button system.

**Home (S06)**
- Same sky + ivory, a read‑only profile summary card, and a sign‑out action.

**Analysing (S04)**
- The dedicated "reading your CV" moment (animated water + status copy) on the ivory base.

---

## 3. Design system

| Element | Decision |
|---|---|
| **Surface** | Warm ivory `#FCFBF8` app‑wide; white cards. |
| **Sky** | Reusable `SkyBackdrop` — warm sun glow + drifting clouds, with `intensity` / `maxClouds` so inner screens can dial it down. Applied via an `atlasSky()` background helper. |
| **Ink** | Near‑black `#0C0C0D` headlines; grey secondary/tertiary for body/meta. |
| **Accent** | Indigo/periwinkle for small accents; blue for the LinkedIn mark and progress fill. |
| **Type** | SF Pro for everything today; the hero routes through a `Typeface.display()` slot that **auto‑activates a real editorial font** the moment an `.otf` is added (see §7). |
| **Buttons** | **Primary** = solid ink, white label. **Secondary** = white + 1px hairline. **Disabled** = light grey. Soft layered shadow + spring press; haptic on sign‑in. |
| **Progress** | `StageProgress` — a row of thin segments filled up to the current step. |
| **Motion** | Staggered fade/rise entrance; slow ambient sky drift; everything respects Reduce Motion. |

---

## 4. Cohesion

Before this pass, the inside screens still used the older look (heavier "glass" cards,
washed‑out glossy buttons, and a decorative boat progress bar) while the Welcome had moved
on. They now share:

- the same **ivory + warm sky** surface,
- the same **button family** (ink primary / white‑hairline secondary),
- the same **minimal progress** language,

so the journey feels like one product from first screen to last.

---

## 5. Technical status (prototype)

- **Native iOS**, SwiftUI, iOS 17+. Project generated with XcodeGen.
- **No backend yet.** Sign‑in and CV parsing are **stubbed**: tapping a provider fabricates a
  session; the CV step runs a mock parser that returns realistic sample data. Persistence is
  local (`UserDefaults`), so force‑quit/relaunch correctly resumes mid‑journey.
- The **journey state machine + restoration** works end to end (Welcome → … → Home).
- Verified on the iOS Simulator; builds clean with zero warnings.
- The Metal ripple shader on the Analysing screen is excluded from the build (needs an
  on‑demand Xcode component) and gated behind a flag.

---

## 6. Design iterations (context)

The Welcome hero went through several explored directions before landing on the sky:

1. **Progress river + nodes** (Find · Join · Belong) — too literal/busy.
2. **Glass river + paper boat** — pretty but read as unfinished/muddy procedurally.
3. **Minimal line + gliding light** — clean but felt bland; didn't explain the product.
4. **Animated "how it works" strip** (Upload → Build → Match) — explanatory but not the vibe.
5. **Warm sunrise sky + clouds** — ✅ current. Warm, alive, calm, and it blends with the
   ivory. This became the app‑wide atmosphere.

The **boat progress indicator** on the inner screens was also retired in favour of the
minimal segmented progress.

---

## 7. Open items & recommendations

**Highest‑impact next steps (design)**
- **Ship a real display typeface** (e.g. General Sans / a refined grotesk). The hero already
  routes through the font slot — drop the `.otf` into `Resources/Fonts/` and register it in
  `project.yml` (`UIAppFonts`) and it activates instantly. This is the single biggest lift.
- **Real brand logos.** LinkedIn is drawn accurately; the GitHub octocat is an approximation.
  Add `logo-linkedin` / `logo-github` image sets and the buttons pick them up automatically.

**Cleanup**
- A few files are now unused after retiring the boat/river (`Current.swift`, `RiverArt.swift`,
  `RiverBand.swift`, `HowItWorks.swift`). Harmless but dead — safe to delete.

**Product / Phase 2 (previously flagged)**
- **Sign in with Apple** is required by App Store review if third‑party login is offered.
- **Dark mode** was intentionally dropped for now; a full app‑wide dark theme is a Phase‑2
  ticket.
- Backend (Supabase auth/storage + the CV parsing edge function) replaces the local stubs.

**Sign‑off needed**
- The current sky + unified‑buttons pass is **uncommitted**, pending your approval. On your
  go‑ahead it will be committed as one clean checkpoint (and the dead files removed).

---

## 8. Definition of done (Phase 1 journey)

A person opens the app, taps a provider, chooses "I'm looking for a job", picks a PDF, watches
the analysing moment, sees their details on the Confirm screen, edits a field, taps "Looks
good", force‑quits, reopens, and lands on Home with their profile intact — all on one
cohesive, warm, minimal surface. This flow works today (with stubbed auth/parsing).
