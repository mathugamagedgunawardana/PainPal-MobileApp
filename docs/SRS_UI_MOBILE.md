# Software Requirements Specification (SRS)

## Painpal Mobile Application — User Interface


| Field                | Value                                         |
| -------------------- | --------------------------------------------- |
| **Document ID**      | SRS-UI-PAINPAL-001                            |
| **Version**          | 1.0                                           |
| **Date**             | 2026-06-16                                    |
| **Product**          | Painpal (Flutter patient mobile app)          |
| **Target platforms** | iOS, Android (primary); web/desktop secondary |
| **Framework**        | Flutter 3.x, Material Design 3                |


---

## 1. Introduction

### 1.1 Purpose

This document specifies the **user interface (UI) requirements** for Painpal, a patient-facing mobile application for migraine tracking, MRI scan upload, health history, analytics, and AI-assisted support. It is intended for:

- UI/UX designers producing mockups or design systems
- Developers implementing or regenerating Flutter screens
- AI code generators that must reproduce a consistent, accessible healthcare UI

### 1.2 Scope

The UI scope covers all screens, navigation, reusable components, visual design tokens, interaction states, and accessibility requirements visible to end users. Backend API contracts are referenced only where they affect on-screen data display.

**In scope**

- Authentication and session shell
- Six-tab main navigation shell
- All primary and modal screens
- Shared component library
- Design system (colors, typography, spacing, motion)
- Empty, loading, and error states
- Permissions-related UI prompts (camera, gallery, microphone)

**Out of scope**

- Server-side business logic
- Database schema implementation details
- CI/CD and build pipelines

### 1.3 Definitions


| Term                 | Definition                                                   |
| -------------------- | ------------------------------------------------------------ |
| **Attack / episode** | A logged migraine event with symptoms and metadata           |
| **Patient**          | Authenticated user with role `patient`                       |
| **Overview tab**     | Home dashboard showing welcome content and summary analytics |
| **FAB**              | Floating action button for chat assistant                    |
| **Draft**            | Locally saved, incomplete migraine form                      |


### 1.4 References

- `README.md` — product overview
- `docs/APPENDIX_A_USER_GUIDE_MOBILE.md` — installation and API linking
- `lib/main.dart` — global theme
- `lib/screens/`* — screen implementations
- `lib/widgets/`* — reusable UI components

---

## 2. Overall Description

### 2.1 Product perspective

Painpal is a **mobile-first, dark-themed healthcare companion** that connects to a Next.js/MongoDB backend. The UI must feel calm, low-friction, and readable for users who may be experiencing pain or cognitive fog.

```
┌─────────────────────────────────────────┐
│              SessionShell               │
│  ┌─────────────┐    ┌─────────────────┐ │
│  │ Landing     │    │ HomeScreen      │ │
│  │ (signed out)│    │ (signed in)     │ │
│  └──────┬──────┘    │ 6 tabs + FAB    │ │
│         │           └─────────────────┘ │
│         ▼                               │
│  ┌─────────────┐                        │
│  │ LoginScreen │ (modal route)          │
│  └─────────────┘                        │
└─────────────────────────────────────────┘
```

### 2.2 User classes and characteristics


| User class                 | Needs                                     | UI implications                                                  |
| -------------------------- | ----------------------------------------- | ---------------------------------------------------------------- |
| **Migraine patient**       | Fast symptom logging, large touch targets | Big toggles, sliders, minimal typing                             |
| **Non-technical user**     | Plain language, no jargon                 | Short labels, helper text under fields                           |
| **User in pain**           | Low cognitive load                        | Single-column layout, card grouping, clear CTAs                  |
| **Offline / poor network** | Local history still visible               | Skeleton loaders, pull-to-refresh, offline-friendly empty states |


### 2.3 Design principles (mandatory)

1. **Single-column mobile layout** — no multi-column forms on phones
2. **Card-based sections** — group related content in rounded containers
3. **Calm healthcare palette** — dark background, lime-green accent (not clinical white)
4. **Touch-friendly** — minimum 48dp tap targets for primary actions
5. **Progressive disclosure** — long forms split into labeled sections with headers
6. **Clear feedback** — loading spinners, snackbars, inline errors, success states
7. **Medical disclaimers** — visible in Settings and near predictive outputs

### 2.4 Assumptions and dependencies

- Material 3 (`useMaterial3: true`) is the component baseline
- App runs in **dark mode only** (no light theme required in v1)
- Patient login is required to access the main shell
- Backend availability affects remote analytics; local SQLite data is fallback

### 2.5 Constraints

- Flutter SDK compatible with Dart ^3.11.0
- Must support safe areas (notch, home indicator)
- Camera/gallery/microphone permissions are platform-managed
- Chat dialog height ≈ 72% of screen height

---

## 3. Design System

### 3.1 Color tokens


| Token             | Hex                                      | Usage                                          |
| ----------------- | ---------------------------------------- | ---------------------------------------------- |
| `background`      | `#0F1218`                                | Scaffold background                            |
| `surface`         | `#171B22`                                | Cards, app bars, inputs, nav bar strip         |
| `surfaceElevated` | `#1A1D24`                                | Secondary cards, unavailable forecast          |
| `accent`          | `#B6F36B`                                | Primary CTA, selected states, chart highlights |
| `accentOn`        | `#0F1218`                                | Text/icons on accent backgrounds               |
| `borderSubtle`    | `grey.shade700`                          | Card borders, dividers                         |
| `errorContainer`  | `colorScheme.errorContainer` @ 35% alpha | Inline error banners                           |
| `warningAmber`    | `amber.shade600–700`                     | Disclaimers, forecast cards                    |
| `infoBlue`        | `blue.shade600`                          | Informational callouts                         |
| `signOutRed`      | `redAccent.shade100`                     | Sign-out actions                               |


Accent glow (landing logo): `accent @ 35% alpha`, blur 32.

### 3.2 Typography

Use Material 3 `textTheme` defaults with these overrides:


| Style                 | Weight    | Notes                                 |
| --------------------- | --------- | ------------------------------------- |
| Screen title (AppBar) | w800      | `titleLarge`                          |
| Section header title  | w700–w800 | `titleSmall` / `titleMedium`          |
| Body                  | regular   | `bodyLarge`, `bodyMedium`             |
| Helper / caption      | regular   | `bodySmall`, `onSurfaceVariant` color |
| Stat values           | w800      | `titleLarge` on stat tiles            |
| CTA label             | w700      | 16sp on primary buttons               |


Line height for marketing copy: **1.45**.

### 3.3 Spacing and layout


| Token                      | Value                                                  |
| -------------------------- | ------------------------------------------------------ |
| Screen horizontal padding  | 16–28dp (20dp standard for forms)                      |
| Section gap                | 16–24dp                                                |
| Card internal padding      | 12–16dp                                                |
| Card border radius         | 12dp (standard), 16–18dp (large cards), 14dp (buttons) |
| Bottom nav + FAB clearance | 96dp bottom padding on scrollable analytics content    |


### 3.4 Elevation and borders

- App bars: `elevation: 0`, `scrolledUnderElevation: 0`
- Cards: 1px border (`accent @ 15–25%` or `grey.shade700`), optional soft shadow on analytics cards
- Inputs: filled, `fillColor: surface`, `borderRadius: 12`

### 3.5 Icons (Material Icons)


| Feature        | Icon                  |
| -------------- | --------------------- |
| Brand / health | `health_and_safety`   |
| Overview       | `home`                |
| Log attack     | `edit_note`           |
| MRI            | `image_search`        |
| History        | `history`             |
| Analytics      | `analytics_outlined`  |
| Settings       | `settings`            |
| Chat FAB       | `chat_bubble_outline` |
| Sign out       | `logout`              |
| Refresh        | `refresh`             |
| Calendar view  | `calendar_month`      |
| List view      | `view_list`           |


### 3.6 Motion

- Pull-to-refresh: accent-colored indicator on surface background
- Dialog open: standard Material fade + scale
- Tab switches: instant (no custom animation required)
- Skeleton loaders on analytics initial load

---

## 4. Information Architecture

### 4.1 Navigation map

```
LandingScreen
  └─[Sign in]→ LoginScreen → pop(true) → HomeScreen

HomeScreen (bottom NavigationBar, 6 destinations)
  ├─ Tab 0: LogAttackScreen (Overview)
  ├─ Tab 1: MigraineFormScreen (Log attack)
  ├─ Tab 2: MriUploadScreen
  ├─ Tab 3: HistoryScreen
  ├─ Tab 4: AnalyticsScreen
  └─ Tab 5: SettingsScreen

Global overlays:
  ├─ ChatDialog (FAB, end-docked)
  └─ Sign-out AlertDialog (HomeScreen bar + Settings)
```

### 4.2 Bottom navigation specification


| Index | Label      | Screen               | Notes                              |
| ----- | ---------- | -------------------- | ---------------------------------- |
| 0     | Overview   | `LogAttackScreen`    | Dashboard, not a marketing landing |
| 1     | Log attack | `MigraineFormScreen` | Full symptom form                  |
| 2     | MRI upload | `MriUploadScreen`    | Image pick + submit                |
| 3     | History    | `HistoryScreen`      | List + calendar for migraines      |
| 4     | Analytics  | `AnalyticsScreen`    | Charts and insights                |
| 5     | Settings   | `SettingsScreen`     | API config, account                |


**Above the nav bar:** a slim `surface` strip with right-aligned **Sign out** text button (red accent).

**FAB:** `ChatButton` docked end-bottom; opens `ChatDialog`.

---

## 5. Functional UI Requirements — Screens

### 5.1 Global app shell (`PainpalApp`)

**REQ-UI-001** The app SHALL use `MaterialApp` with title `Painpal`, `debugShowCheckedModeBanner: false`.

**REQ-UI-002** Theme SHALL use `ColorScheme.fromSeed(seedColor: #B6F36B, brightness: dark)` and `scaffoldBackgroundColor: #0F1218`.

**REQ-UI-003** `InputDecorationTheme` SHALL use filled inputs on `#171B22` with 12dp corner radius.

---

### 5.2 Landing screen (signed out)

**Screen ID:** `SCR-LANDING`

**Purpose:** Brand introduction and entry to authentication.


| Element     | Requirement                                                                                       |
| ----------- | ------------------------------------------------------------------------------------------------- |
| Layout      | Centered column, horizontal padding 28dp                                                          |
| Logo        | 96×96dp rounded square (24dp radius), accent fill, `health_and_safety` icon 52dp                  |
| Title       | "Painpal", centered, headlineMedium w800                                                          |
| Tagline     | "Track migraines, review history, and stay on top of your patterns — privately and in one place." |
| Primary CTA | FilledButton "Sign in", accent bg, full width, vertical padding 16dp                              |
| Footer note | Small text: account required; API URL configurable after sign-in                                  |


**States:** static (no loading).

---

### 5.3 Login screen

**Screen ID:** `SCR-LOGIN`

**Purpose:** Patient authentication against Next.js backend.


| Element      | Requirement                                                                 |
| ------------ | --------------------------------------------------------------------------- |
| AppBar       | Title "Sign in", surface background                                         |
| Intro        | Title "MongoDB / Next.js backend" + emulator URL hint                       |
| Form card    | Surface container, 12dp radius, grey border                                 |
| Fields       | Email (hint `patient@painpal.com`), Password (obscured)                     |
| Submit       | FilledButton "Sign in"; shows 22dp `CircularProgressIndicator` when loading |
| Error banner | Full-width error container below form when login fails                      |
| Success      | Pop route with `true`; non-patient roles show role error                    |


**Validation:** Empty email/password → inline error "Enter email and password."

---

### 5.4 Overview tab (`LogAttackScreen`)

**Screen ID:** `SCR-OVERVIEW`

**Purpose:** Patient dashboard with quick log CTA and summary stats from backend.


| Element         | Requirement                                                                  |
| --------------- | ---------------------------------------------------------------------------- |
| AppBar          | Title "Painpal"                                                              |
| Body            | `RefreshIndicator` + scrollable list, padding 16dp                           |
| Header card     | Welcome card: logo tile + "Welcome to Painpal" + backend URL display         |
| Primary CTA     | `FilledButton.icon` "Log migraine attack" → pushes full `MigraineFormScreen` |
| Analytics block | Shown for authenticated patients only                                        |
| Loading         | Centered `CircularProgressIndicator` while fetching                          |
| Empty hint      | "Pull to refresh to load analytics."                                         |
| Error           | Red-tinted error container with API message                                  |


**Analytics body (when data loaded):**


| Component            | Content                                                                            |
| -------------------- | ---------------------------------------------------------------------------------- |
| Section title        | "Your data (last 90 days, MongoDB)"                                                |
| Next attack forecast | `NextAttackForecastCard` OR unavailable reason card                                |
| Stat grid            | 2×2 tiles: Episodes (30d), Migraine days (month), Avg severity, Total events (90d) |
| Optional tile        | Adherence % when available                                                         |
| Triggers list        | Top 5 triggers with name + count (accent count)                                    |
| Footer note          | Explains logging via Log attack tab                                                |


**Non-patient state:** Message to sign in with patient account.

**Bootstrap state:** Full-screen centered spinner until API base URL resolves.

---

### 5.5 Log migraine attack (`MigraineFormScreen`)

**Screen ID:** `SCR-MIGRAINE-FORM`

**Purpose:** Structured symptom capture with draft support and backend submission.

**AppBar:** Title "Log migraine attack"

#### Section A — When did the attack happen?


| Field         | Control                            | Validation                 |
| ------------- | ---------------------------------- | -------------------------- |
| Duration      | Large numeric field + "hours" unit | Required, positive integer |
| Pain location | `HeadPainSitePicker`               | Required selection         |


**Head pain sites:** Left temple, Right temple, Forehead, Occipital, Back, Diffuse, Neck — diagram + chip row.

#### Section B — Describe the pain


| Field     | Control                                        |
| --------- | ---------------------------------------------- |
| Character | Dropdown: Throbbing, Pressure                  |
| Intensity | `IntensitySlider` 1–10 with live value display |


#### Section C — Associated symptoms

Binary `SymptomToggle` for each:

- Nausea, Vomit, Sound Sensitivity, Light Sensitivity, Visual Disturbances, Sensory Issues

#### Section D — Neurological symptoms

Binary toggles with helper descriptions:

- Speech Difficulty (Dysphasia), Speech Slurring (Dysarthria), Dizziness, Ringing in Ears, Hearing Loss, Double Vision, Visual Field Defect, Loss of Coordination, Loss of Consciousness, Abnormal Sensations

#### Section E — Optional details


| Field     | Control            |
| --------- | ------------------ |
| Age       | Numeric text field |
| Attack ID | Text field         |


#### Actions


| Button         | Behavior                                                  |
| -------------- | --------------------------------------------------------- |
| Save draft     | Persists to local storage; snackbar "Draft saved locally" |
| Submit attack  | Validates form, POSTs to API, saves SQLite, clears draft  |
| Submit loading | Disabled with progress indicator                          |


#### Result display (post-submit)

Cards showing:

- Predicted migraine type
- AI/backend summary text
- Success snackbar: "Attack saved to your clinic record."

**Draft restore:** On open, load draft from shared preferences and populate all fields.

---

### 5.6 MRI upload screen

**Screen ID:** `SCR-MRI-UPLOAD`

**AppBar:** Title "Upload MRI Scan"


| Element          | Requirement                                                                  |
| ---------------- | ---------------------------------------------------------------------------- |
| Header           | `SectionHeader` — title + subtitle                                           |
| Preview area     | 280dp height; dashed-style border (grey default, accent when image selected) |
| Empty preview    | `image_not_supported` icon + "No image selected" + format hint               |
| Selected preview | Full-bleed image + close button (top-right circle avatar)                    |
| Source buttons   | Row: "Take Photo" (camera), "From Gallery"                                   |
| Ready banner     | Accent-tinted info box when image selected                                   |
| Submit           | `MigraineButton` "Analyze MRI Scan" — disabled until image selected          |
| Loading          | Submit button shows progress                                                 |
| Results          | Prediction label (e.g. Tumor / Non-tumor) + confidence %                     |
| Errors           | Snackbar with error message                                                  |


---

### 5.7 History screen

**Screen ID:** `SCR-HISTORY`

**AppBar:** Title "History" + refresh `IconButton`

#### Migraine section


| Element       | Requirement                                               |
| ------------- | --------------------------------------------------------- |
| Header        | `SectionHeader` — Migraine Attack History                 |
| View toggle   | `SegmentedButton`: List                                   |
| List view     | Chronological cards (`_MigraineCard`)                     |
| Calendar view | Month grid with attack markers; month navigation          |
| Empty state   | Inbox icon 64dp + "No migraine records yet" + helper text |
| Loading       | Centered spinner in section                               |


**Migraine card content:**

- Attack number, timestamp (formatted)
- Duration, intensity, frequency, location
- Predicted type badge (if available)
- Expandable detail (optional)

#### MRI section


| Element     | Requirement                                                                |
| ----------- | -------------------------------------------------------------------------- |
| Header      | MRI Scan History                                                           |
| Cards       | Scan number, timestamp, thumbnail (if file exists), prediction, confidence |
| Empty state | Image icon + "No MRI scans yet"                                            |


**Data source:** Merge local SQLite + remote patient API when authenticated.

---

### 5.8 Analytics screen

**Screen ID:** `SCR-ANALYTICS`

**AppBar:** Title "Analytics" (w800)


| Element      | Requirement                                     |
| ------------ | ----------------------------------------------- |
| Initial load | `AnalyticsSkeleton` placeholder                 |
| Empty        | Centered "No analytics yet"                     |
| Refresh      | Pull-to-refresh reloads data                    |
| Range filter | Chips: Last 7 days, Last 30 days, Last 3 months |
| Trend view   | Chips: Week, Month                              |


#### Content blocks (top to bottom)

1. **Summary stats row** — total migraines, avg intensity, avg duration (icon + value cards)
2. **Pain level distribution** — low / medium / high counts with color coding
3. **Next attack forecast** — `NextAttackForecastCard` or unavailable card
4. **Trend chart** — bar chart with spike highlighting (`AnalyticsBarChart`)
5. **Trigger breakdown** — horizontal bar or list with icons
6. **Medication effectiveness** — usage bars + overuse warning banner if applicable
7. **AI summary card** — paragraph insight from server or fallback text
8. **AI insights list** — up to 3 bullet insight cards

**Fallback behavior:** When backend unavailable, compute from local SQLite; may show demo/dummy trigger data with clear labeling in dev contexts.

---

### 5.9 Settings screen

**Screen ID:** `SCR-SETTINGS`

**AppBar:** Title "Settings"

#### Account section (when signed in)

- Signed-in email display
- Outlined sign-out button (red styling)
- Confirmation dialog before logout

#### API configuration


| Field             | Label                      | Hint                        |
| ----------------- | -------------------------- | --------------------------- |
| API Base URL      | Required for backend       | `https://your-backend-host` |
| Patient ID        | Optional identifier        | `patient-12345`             |
| Doctor profile ID | Patients only; clinic chat | Mongo ObjectId              |


Info callout: internet + running API server required.

**Save:** Primary `MigraineButton` "Save Settings" → success snackbar with check icon on accent background.

#### Disclaimer section

Amber-bordered card with three subsections:

1. Educational Purpose Only
2. Consult Healthcare Professionals
3. No Emergency Use

#### About section

- App name PainPal, version 1.0.0
- Short description

---

### 5.10 Chat dialog (modal)

**Screen ID:** `MODAL-CHAT`

**Trigger:** FAB on `HomeScreen`


| Element                  | Requirement                                                      |
| ------------------------ | ---------------------------------------------------------------- |
| Container                | Dialog, 16dp inset, 16dp top corner radius, height 72% of screen |
| Header                   | Accent bar with title + close button                             |
| Tabs (patients)          | Tab 1: "Your doctor", Tab 2: "AI assistant"                      |
| Tabs (guest/non-patient) | AI assistant only                                                |
| Message list             | Scrollable bubbles; user right-aligned, assistant left           |
| Input row                | Text field + send; AI tab adds microphone / voice controls       |
| Timestamps               | Formatted with `intl`                                            |
| Doctor tab               | Thread from `doctor_patient_chat_api`; composer at bottom        |


**AI assistant features:**

- Text input to Gemini
- Optional TTS for responses
- Voice input via platform speech recognition
- Loading indicator while generating

---

### 5.11 Sign-out confirmation dialog

**Screen ID:** `MODAL-SIGNOUT`

- Title: "Sign out"
- Body: "You will need to sign in again to use the app."
- Actions: Cancel (text), Sign out (text, destructive intent)

---

## 6. Reusable Component Library

### 6.1 Component catalog


| Component                    | File reference                   | Purpose                                |
| ---------------------------- | -------------------------------- | -------------------------------------- |
| `SectionHeader`              | `custom_widgets.dart`            | Title + subtitle + optional icon       |
| `IntensitySlider`            | `custom_widgets.dart`            | 1–10 pain slider in bordered container |
| `SymptomToggle`              | `custom_widgets.dart`            | Large binary symptom switch            |
| `CustomDropdown`             | `custom_widgets.dart`            | Styled dropdown with description       |
| `MigraineButton`             | `custom_widgets.dart`            | Primary full-width action button       |
| `HeadPainSitePicker`         | `head_pain_site_picker.dart`     | Head diagram + site chips              |
| `AnalyticsCard`              | `analytics_widgets.dart`         | Bordered analytics container           |
| `AnalyticsFilterChips`       | `analytics_widgets.dart`         | Horizontal choice chips                |
| `AnalyticsBarChart`          | `analytics_widgets.dart`         | Trend visualization                    |
| `AnalyticsSkeleton`          | `analytics_widgets.dart`         | Loading placeholder                    |
| `NextAttackForecastCard`     | `next_attack_forecast_card.dart` | Amber forecast panel                   |
| `ChatButton` / `ChatDialog`  | `chat_widget.dart`               | FAB + chat modal                       |
| `_StatTile`                  | `log_attack_screen.dart`         | Label + value metric tile              |
| `_SettingCard`               | `settings_screen.dart`           | Settings field wrapper                 |
| `_MigraineCard` / `_MriCard` | `history_screen.dart`            | History list items                     |


### 6.2 `SectionHeader` specification

```
┌──────────────────────────────────────┐
│ [icon]  Title (w700)                 │
│         Subtitle (bodySmall, muted)  │
└──────────────────────────────────────┘
```

### 6.3 `SymptomToggle` specification

- Full-width tappable row, min height ~56dp
- Border 2px: accent when on, grey when off
- Background: accent @ 10% when on
- Label (titleMedium) + optional description (bodySmall)
- Trailing check icon when selected

### 6.4 `IntensitySlider` specification

- Label + description above
- Track height 8dp, thumb radius 14dp
- Active track + thumb: accent
- Large numeric readout below slider (headlineSmall, accent, bold)

### 6.5 `MigraineButton` specification

- Full width, min height 48dp
- Accent background, dark text
- Optional leading icon
- Disabled state: reduced opacity, null `onPressed`

---

## 7. Interaction States

### 7.1 Global states matrix


| State          | Visual treatment                                                   |
| -------------- | ------------------------------------------------------------------ |
| **Loading**    | `CircularProgressIndicator` (accent on dark) or skeleton           |
| **Empty**      | Large muted icon (64dp) + title + helper subtitle                  |
| **Error**      | Error container with border + `onErrorContainer` text; or snackbar |
| **Success**    | Accent snackbar with check icon                                    |
| **Disabled**   | `onPressed: null`, greyed controls                                 |
| **Refreshing** | `RefreshIndicator` at top of scroll view                           |


### 7.2 Form validation

- Invalid submit: form validator messages on required fields
- Auth required: snackbar "Sign in as a patient to save..."
- Missing API URL: snackbar/exception message directing user to Settings

### 7.3 Snackbar patterns


| Message type | Background                         |
| ------------ | ---------------------------------- |
| Neutral      | Default theme                      |
| Success      | `#B6F36B` with white/dark icon     |
| Error        | Default with error text in content |


---

## 8. Accessibility Requirements

**REQ-A11Y-001** All interactive elements SHALL have minimum **48×48dp** touch targets.

**REQ-A11Y-002** Color contrast for body text on `#0F1218` / `#171B22` SHALL meet WCAG 2.1 AA (4.5:1 for normal text).

**REQ-A11Y-003** Form fields SHALL have visible `labelText` (not placeholder-only).

**REQ-A11Y-004** Icons used as sole controls SHALL have `tooltip` or semantic `Semantics` labels.

**REQ-A11Y-005** Pain intensity slider SHALL expose value changes to screen readers.

**REQ-A11Y-006** Medical disclaimers SHALL be readable without relying on color alone (include text headings).

**REQ-A11Y-007** Support system font scaling (`textScaleFactor`) without clipping primary CTAs.

---

## 9. Platform-Specific UI Notes

### 9.1 Android

- Emulator API hint: `http://10.0.2.2:3000`
- `image_picker` camera/gallery intents
- Notification permission UI for medication reminders (system dialog)
- Reverse port script available for local dev

### 9.2 iOS

- Camera, photo library, microphone, speech recognition permission strings in `Info.plist`
- Safe area respects notch and home indicator

### 9.3 Permissions UI flow

When permission denied:

- Show snackbar or inline message explaining which feature is blocked
- Do not crash; degrade gracefully (e.g. hide voice button if mic unavailable)

---

## 10. Content and Copy Guidelines

### 10.1 Tone

- Plain, reassuring, non-alarmist
- Avoid definitive diagnostic language; use "prediction", "forecast", "may indicate"
- Short sentences; avoid medical abbreviations without expansion

### 10.2 Required disclaimer copy (Settings)

Include verbatim themes:

1. Educational and self-tracking only; not a medical diagnosis
2. Consult qualified healthcare professionals
3. Not for emergency use — contact emergency services

### 10.3 Forecast disclaimer

Next-attack cards MUST include: "For planning only—not medical advice."

---

## 11. Data Display Mapping (UI ↔ API)


| UI location           | Data fields displayed                                                                                           |
| --------------------- | --------------------------------------------------------------------------------------------------------------- |
| Overview stats        | `episodesLast30Days`, `migraineDaysThisMonth`, `avgSeverity`, `totalEpisodes`, `adherencePercent`, `triggers[]` |
| Next attack card      | `confidenceTier`, `confidenceCaption`, `basedOnRecords`, date range, `usedHistoryFallback`                      |
| Migraine result       | `predictedType`, `summary` from `/api/summary`                                                                  |
| MRI result            | `prediction`, `confidence` from `/api/mri/predict`                                                              |
| History migraine card | `attackId`, `timestamp`, `durationHours`, `intensity`, `location`, `type`                                       |
| History MRI card      | `mriId`, `timestamp`, `prediction`, `confidence`, local thumbnail                                               |
| Analytics             | Aggregated episodes, severity buckets, weekly trend, AI summary payload                                         |


---

## 12. UI Generation Acceptance Criteria

A generated UI implementation SHALL be considered complete when:

### 12.1 Navigation

- [ ] Signed-out users see Landing → Login → Home flow
- [ ] Signed-in users see 6-tab bottom nav with correct labels and icons
- [ ] FAB opens chat dialog from any main tab
- [ ] Sign out returns to Landing screen

### 12.2 Visual fidelity

- [ ] Dark theme colors match Section 3 tokens
- [ ] All screens use card-based layout with consistent 12dp radius
- [ ] Primary buttons use accent `#B6F36B`
- [ ] App bars use surface `#171B22` with zero elevation

### 12.3 Functional completeness

- [ ] Migraine form includes all 4 symptom sections + optional fields
- [ ] Head pain picker supports 6 anatomical sites
- [ ] MRI screen supports camera + gallery + preview + submit
- [ ] History supports list/calendar toggle for migraines
- [ ] Analytics shows filters, charts, AI summary, and skeleton loader
- [ ] Settings persists API URL, patient ID, doctor profile ID

### 12.4 States

- [ ] Every data-driven screen handles loading, empty, and error
- [ ] Forms show validation and submission loading
- [ ] Pull-to-refresh works on Overview and Analytics

### 12.5 Accessibility

- [ ] Touch targets ≥ 48dp on primary actions
- [ ] Labels present on all text fields

### 12.6 Compliance copy

- [ ] Settings disclaimer block present
- [ ] Predictive outputs include non-diagnostic framing

---

## 13. Appendix A — Screen Wireframe Sketches (ASCII)

### Home shell

```
┌────────────────────────────┐
│ AppBar (screen-specific)   │
├────────────────────────────┤
│                            │
│   [ Scrollable content ]   │
│                            │
│                      (FAB) │
├────────────────────────────┤
│            [ Sign out ]    │
├────────────────────────────┤
│ 🏠 📝 🖼 📜 📊 ⚙️          │
│ Ov  Log MRI Hist An  Set   │
└────────────────────────────┘
```

### Migraine form (excerpt)

```
┌─ When did the attack happen? ─┐
│ Duration [____] hours         │
│ [ Head diagram + site chips ] │
└───────────────────────────────┘
┌─ Describe the pain ───────────┐
│ Character [ Throbbing ▼ ]     │
│ Pain Intensity ═══●═══ 7      │
└───────────────────────────────┘
┌─ Associated symptoms ─────────┐
│ [✓] Nausea                    │
│ [ ] Sound Sensitivity         │
└───────────────────────────────┘
[ Save draft ]  [ Submit attack ]
```

---

## 14. Appendix B — File-to-Screen Traceability


| Screen ID         | Primary Dart file                                                |
| ----------------- | ---------------------------------------------------------------- |
| SCR-LANDING       | `lib/screens/landing_screen.dart`                                |
| SCR-LOGIN         | `lib/screens/login_screen.dart`                                  |
| SCR-OVERVIEW      | `lib/screens/log_attack_screen.dart`                             |
| SCR-MIGRAINE-FORM | `lib/screens/migraine_form_screen.dart`                          |
| SCR-MRI-UPLOAD    | `lib/screens/mri_upload_screen.dart`                             |
| SCR-HISTORY       | `lib/screens/history_screen.dart`                                |
| SCR-ANALYTICS     | `lib/screens/analytics_screen.dart`                              |
| SCR-SETTINGS      | `lib/screens/settings_screen.dart`                               |
| MODAL-CHAT        | `lib/widgets/chat_widget.dart`                                   |
| SHELL             | `lib/screens/home_screen.dart`, `lib/screens/session_shell.dart` |
| THEME             | `lib/main.dart`                                                  |


---

## 15. Revision History


| Version | Date       | Author | Changes                                           |
| ------- | ---------- | ------ | ------------------------------------------------- |
| 1.0     | 2026-06-16 | —      | Initial SRS derived from Painpal Flutter codebase |


