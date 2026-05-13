# Cursor Prompt — Migraine App UI Redesign

## OBJECTIVE

Redesign the entire UI of this migraine management app. Keep every screen's layout, navigation structure, buttons, and data logic exactly as-is. Only change the visual design system: colors, typography, spacing, illustration style, and add a light/dark theme toggle.

The new design should feel like a **friendly consumer wellness app** — warm, approachable, emoji-illustrated — similar in spirit to mood-tracking and pet-care apps. NOT clinical, NOT dark, NOT neon-on-black.

---

## DESIGN SYSTEM

### Color Palette

#### Light Theme (default)
```
--bg-primary: #FFFFFF
--bg-secondary: #F7F5FF         /* soft lavender tint */
--bg-tertiary: #EFF0FF          /* page background */
--bg-card: #FFFFFF
--bg-card-elevated: #FAFAFA

--accent-primary: #7C6FF7       /* soft violet — main brand color */
--accent-primary-light: #EDE9FE /* violet tint for backgrounds */
--accent-secondary: #F472B6     /* pink — secondary accent */
--accent-secondary-light: #FDF2F8
--accent-success: #4ADE80       /* mint green */
--accent-success-light: #F0FDF4
--accent-warning: #FBBF24       /* amber */
--accent-warning-light: #FFFBEB
--accent-danger: #F87171        /* soft red */
--accent-danger-light: #FFF1F2

--text-primary: #1C1B2E         /* deep navy-black */
--text-secondary: #6B6880       /* muted purple-gray */
--text-tertiary: #A89FC0        /* hint text */
--text-on-accent: #FFFFFF

--border-default: #E8E5F0
--border-focus: #7C6FF7

--shadow-card: 0 2px 12px rgba(124, 111, 247, 0.08)
--shadow-elevated: 0 4px 24px rgba(124, 111, 247, 0.12)
```

#### Dark Theme
```
--bg-primary: #13111E
--bg-secondary: #1C1929
--bg-tertiary: #0F0E18
--bg-card: #1E1B2E
--bg-card-elevated: #252238

--accent-primary: #9B8FFB       /* lighter violet for dark bg */
--accent-primary-light: #2A2550
--accent-secondary: #F9A8D4
--accent-secondary-light: #3B1D2E
--accent-success: #6EE7B7
--accent-success-light: #0D2E1F
--accent-warning: #FCD34D
--accent-warning-light: #2E2210
--accent-danger: #FCA5A5
--accent-danger-light: #2E1010

--text-primary: #F0EEF8
--text-secondary: #A89FC0
--text-tertiary: #6B6880
--text-on-accent: #13111E

--border-default: #2E2A42
--border-focus: #9B8FFB

--shadow-card: 0 2px 12px rgba(0, 0, 0, 0.4)
--shadow-elevated: 0 4px 24px rgba(0, 0, 0, 0.5)
```

### Typography
```
Font family: 'Inter', system-ui, sans-serif
(import from Google Fonts)

--font-display: 700, 26px, line-height 1.2    /* hero numbers, page titles */
--font-heading: 600, 20px, line-height 1.3    /* section headings */
--font-subheading: 600, 16px, line-height 1.4 /* card titles */
--font-body: 400, 14px, line-height 1.6       /* body copy */
--font-caption: 400, 12px, line-height 1.5    /* labels, captions */
--font-label: 600, 11px, letter-spacing 0.06em, uppercase /* tag labels */
```

**Text reduction rule:** Wherever current UI has a sentence of explanation, replace with a 2–3 word label + emoji icon. E.g. "Forecasts are probabilistic and for decision support only — not a diagnosis or emergency guidance." → `⚠️ For awareness only`

### Border Radius
```
--radius-sm: 8px
--radius-md: 12px
--radius-lg: 16px
--radius-xl: 24px
--radius-pill: 999px
```

### Spacing Scale
```
4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48px
```

### Elevation / Cards
Cards use: `background: var(--bg-card)`, `border-radius: var(--radius-lg)`, `border: 1px solid var(--border-default)`, `box-shadow: var(--shadow-card)`. No harsh lines — soft, floaty cards.

---

## EMOJI ILLUSTRATION SYSTEM

Replace all icon-only indicators with emoji + short text combos. Use native emoji (no image assets needed). Map as follows:

| Context | Emoji | Usage |
|---------|-------|-------|
| Migraine / attack | 🧠 | attack log entries, history items |
| Pain severity | 🔥 (high) / 😣 (medium) / 😐 (low) | pain level indicators |
| Forecast / prediction | 🔮 | forecast card header |
| Timer / duration | ⏱️ | duration fields |
| Calendar / history | 📅 | history tab, date pickers |
| Stats / trends | 📊 | stats tab, charts |
| Triggers | ⚡ | trigger list items |
| Medication | 💊 | medication habit |
| Nausea | 🤢 | nausea symptom toggle |
| Light sensitivity | 💡 | photophobia toggle |
| Sound sensitivity | 🔊 | phonophobia toggle |
| Aura / visual | 👁️ | aura symptom toggle |
| Sleep trigger | 😴 | sleep disruption trigger |
| Bright lights | ☀️ | bright lights trigger |
| Loud noise | 🔊 | loud noise trigger |
| MRI / scan | 🧬 | MRI tab, upload screen |
| AI assistant | 🤖 | AI chat tab |
| Doctor | 👩‍⚕️ | doctor message tab |
| Appointment | 📋 | appointment booking |
| Profile | 👤 | profile/avatar fallback |
| Success | ✅ | completed actions |
| Warning | ⚠️ | disclaimers, probabilistic notices |
| Home | 🏠 | home tab |
| Left pain | ← (styled) | head diagram left |
| Right pain | → (styled) | head diagram right |
| Improvement | 📈 | positive trends |

**Illustration blobs:** On the Home screen hero card and the Stats summary card, add a decorative cluster of 3–4 large emoji (48–64px, low opacity ~0.15) as background decoration inside the card. E.g. `🧠 ⚡ 💊` floating behind the text. Use `position: absolute`, `pointer-events: none`, `user-select: none`.

---

## THEME TOGGLE

Add a theme toggle button in the top-right of every main screen (near the profile header chevron). Use a sun/moon emoji toggle:
- Light mode shows: `🌙` button (tap to go dark)
- Dark mode shows: `☀️` button (tap to go light)

Store preference in `AsyncStorage` with key `@theme_preference`. Apply via a `ThemeContext` wrapping the entire app. On launch, read stored preference; fallback to system default.

```typescript
// ThemeContext.tsx
type Theme = 'light' | 'dark'
const ThemeContext = React.createContext<{
  theme: Theme
  toggleTheme: () => void
}>({ theme: 'light', toggleTheme: () => {} })
```

---

## COMPONENT REDESIGN SPECS — SCREEN BY SCREEN

### Bottom Navigation Bar
- Background: `var(--bg-card)` with top border `1px solid var(--border-default)`
- Active tab: `var(--accent-primary)` color, filled icon + label
- Inactive: `var(--text-tertiary)`, outline icon
- Center "+" button: pill-shaped, `var(--accent-primary)` background, white "+" icon, `box-shadow: var(--shadow-elevated)`, slightly elevated above the bar
- Labels: 10px, font-label style
- Tab icons replace with emoji + label:
  - Home: 🏠 Home
  - Stats: 📊 Stats
  - [+] (center, no label)
  - History: 📅 History
  - MRI: 🧬 MRI

### Floating Action Buttons (timer ⏱️ and chat 💬)
- Remove the separate floating green squares
- Integrate timer as a persistent bottom sheet trigger
- Integrate chat as a floating bubble: circular, `var(--accent-secondary)` background, `💬` emoji, 52px diameter, positioned bottom-right above nav bar, `box-shadow: var(--shadow-elevated)`

---

### HOME SCREEN

**Header**
- User avatar: circular, gradient background `linear-gradient(135deg, var(--accent-primary), var(--accent-secondary))`, white initials
- Username: `var(--text-primary)`, 16px/600
- Handle: `var(--text-tertiary)`, 13px
- Theme toggle (🌙/☀️): top right

**Greeting card** (replaces "Hi Sarah" card)
- Background: `var(--accent-primary-light)`
- Border: none
- Large emoji illustration cluster (background): `🧠 ⚡ 💊` at 48px, opacity 0.12
- Title: "Hey, Sarah 👋" — 20px/700, `var(--text-primary)`
- Subtitle: "Here's your migraine snapshot" — 13px, `var(--text-secondary)`

**Primary CTA — Log an attack**
- Full-width pill button
- Background: `var(--accent-primary)`
- Text: white, 15px/600, `🧠 Log an attack`
- `border-radius: var(--radius-pill)`

**Secondary CTA — Pain timer**
- Full-width pill button, outlined style
- Border: `2px solid var(--accent-primary)`
- Background: transparent
- Text: `var(--accent-primary)`, `⏱️ Pain started — start timer`

**Forecast card**
- Background: `var(--accent-primary-light)`
- Header row: `🔮 Forecast` label (accent color, 11px/600/uppercase) + `⚠️ For awareness only` (warning color, 10px) — right aligned
- Title: "Probable Migraine" — 22px/700, `var(--text-primary)`
- Stat chips (Typical length, Episodes/mo, Pain est.):
  - `background: var(--bg-card)`, `border-radius: var(--radius-md)`, `border: 1px solid var(--border-default)`
  - Emoji prefix: ⏱️ for length, 📅 for episodes, 🔥 for pain
  - Value: 18px/700, `var(--accent-primary)`
  - Label: 11px, `var(--text-secondary)`
- Symptom tags (Nausea 71%, Photophobia 61% etc.):
  - Pill chips: `background: var(--accent-secondary-light)`, `color: var(--accent-secondary)`, `border-radius: var(--radius-pill)`, 12px/600
  - Prefix emoji: 🤢 Nausea / 💡 Photophobia / 🔊 Phonophobia / 👁️ Aura

**Your Patterns section**
- Section title: "Your patterns 📈" — 16px/600
- Subtitle: "Last 3 months" — 12px, `var(--text-tertiary)`
- Stats list items: card rows with left emoji, label in `var(--text-secondary)`, value right-aligned in `var(--text-primary)` 600 weight
  - 🧠 Attacks / 30 days → **6**
  - 📅 Migraine days this month → **3**
  - 🔥 Avg pain level → **7.3**
  - 📊 Total logged (90 days) → **7**
  - 💊 Medication habit → **85%** (show as green progress pill)

**Triggers section**
- Title: "Common triggers ⚡" — 16px/600
- Trigger items as horizontal scrollable pill chips:
  - ☀️ Bright lights
  - 🔊 Loud noise
  - 😴 Sleep disruption
  - Each chip: `background: var(--accent-warning-light)`, `color: var(--accent-warning)`, pill shape, 13px/600

---

### STATS SCREEN

**This month at a glance — hero section**
- Three large metric cards in a row:
  - 🧠 **6** / Migraines — `var(--accent-primary)`
  - 🔥 **7.3** / Avg pain — `var(--accent-danger)`
  - ☀️ **Bright lights** / Top trigger — `var(--accent-warning)`
- Cards: `background: var(--bg-secondary)`, no border, `border-radius: var(--radius-lg)`, padding 16px, value 24px/700, label 11px `var(--text-secondary)`

**AI Summary card**
- Background: `var(--accent-success-light)`
- Left border accent: `4px solid var(--accent-success)`
- Header: `🤖 AI Summary` — 13px/600, `var(--accent-success)` (dark)
- Body text: reduced to 2 sentences max. Remove all the verbose copy.
- Time filter tabs (Last 7 days / Last 30 days / Last 3 months):
  - Active: `background: var(--accent-primary)`, white text, `border-radius: var(--radius-pill)`
  - Inactive: `background: var(--bg-secondary)`, `var(--text-secondary)`, no border

**Migraine Trends chart**
- Card with title: "Migraine trends 📊" — 16px/600
- Week/Month toggle: pill tab group, same style as time filters
- Chart line: `var(--accent-primary)`, area fill: `var(--accent-primary)` at 10% opacity
- Grid lines: `var(--border-default)`
- Axis labels: 11px, `var(--text-tertiary)`

**Pain and Duration chart**
- Title: "Pain & duration ⏱️"
- Bars: Low = `var(--accent-success)`, Medium = `var(--accent-warning)`, High = `var(--accent-danger)`
- Labels below bars: 12px, `var(--text-secondary)`, with emoji prefix (😐 Low / 😣 Medium / 🔥 High)

**Trigger Insights section**
- Title: "Trigger insights ⚡"
- Horizontal bar chart or ranked pill list with percentage fills

---

### HISTORY SCREEN

**Header**
- Title: "Attack History 📅" — 22px/700
- Subtitle: "Your recorded attacks" — 13px, `var(--text-tertiary)`

**Calendar / List toggle**
- Pill tab toggle, same design pattern as other toggles
- Calendar mode:
  - Days with attacks: circular badge, `var(--accent-primary)` background, white number
  - Attack count dot: smaller `var(--accent-danger)` dot
  - Today: `border: 2px solid var(--accent-primary)`
  - Navigation arrows: `var(--accent-primary)`

**List view — Attack cards**
- Card: white bg, shadow, `border-radius: var(--radius-lg)`
- Header row: `🧠 Attack #1` — 15px/600, `var(--text-primary)` + date right-aligned, 12px, `var(--text-tertiary)`
- Stat chips in 2×2 grid:
  - ⏱️ Duration → value
  - 🔥 Intensity → value (color-code: green <4, amber 4–7, red >7)
  - 📅 Frequency → value
  - 📍 Location → value
- Intensity chip background: `var(--accent-danger-light)`, text `var(--accent-danger)` if high

---

### LOG ATTACK FLOW

**Step 1 — Timing**
- Page title: "Log attack 🧠" — back arrow left
- Section: "⏱️ When did it happen?"
- Duration input: large, centered number input with `hours` unit label
- Pain location diagram:
  - Head outline: `stroke: var(--border-default)`, `stroke-width: 2`
  - Selected zone: `fill: var(--accent-primary)`, `opacity: 0.4`
  - Unselected dot: `fill: var(--text-tertiary)`
- Location chips (Left / Right / Forehead / Back / Diffuse / Neck):
  - Selected: `background: var(--accent-primary)`, white text, `✓` prefix
  - Unselected: `background: var(--bg-secondary)`, `var(--text-secondary)`

**Step 2 — Symptoms**
- Section: "🤢 Associated symptoms"
- Subtitle: "Select all that apply" — 13px, `var(--text-tertiary)`
- Toggle rows: replace toggles with **tap-to-select emoji cards**:
  - Each symptom = rounded card with large emoji (32px) + name + description
  - Selected: `border: 2px solid var(--accent-primary)`, `background: var(--accent-primary-light)`
  - Unselected: `border: 1px solid var(--border-default)`, `background: var(--bg-card)`
  - Symptoms: 🤢 Nausea / 🤮 Vomit / 🔊 Sound Sensitivity / 💡 Light Sensitivity / 👁️ Visual Disturbances / 🫁 Sensory Issues

- Section: "🧠 Neurological symptoms"
- Subtitle: "More serious — report all" — warning color
- Neurological cards same style but with `border-left: 4px solid var(--accent-danger)` when selected

**Step 3 — Optional details**
- Section: "ℹ️ Optional details"
- Age input: standard text input, styled per design system
- Attack ID: same
- Save buttons:
  - Primary: `☁️ Save to clinic record` — `var(--accent-primary)` full-width pill
  - Secondary: `📝 Save as draft` — outlined pill

---

### ATTACK TIMER BOTTOM SHEET

- Bottom sheet with `border-radius: var(--radius-xl) var(--radius-xl) 0 0`
- Background: `var(--bg-card)`
- Handle bar: `4px × 40px`, `var(--border-default)`, centered
- Title: "⏱️ Attack timer" — 16px/600
- Time display: `0m 12s` — 40px/700, `var(--accent-primary)` monospace
- Subtitle: "Stop when ready to describe" — 13px, `var(--text-tertiary)`
- CTA: `🧠 Stop & log attack` — `var(--accent-primary)` pill
- Dismiss: `Discard timer` — `var(--text-tertiary)`, 14px, no border, tap to dismiss

---

### MRI UPLOAD SCREEN

- Title: "Upload Brain MRI 🧬" — 22px/700
- Subtitle: "Help us analyze your imaging" — 13px, `var(--text-tertiary)`
- Upload drop zone:
  - `border: 2px dashed var(--border-default)`
  - `border-radius: var(--radius-lg)`
  - Background: `var(--bg-secondary)`
  - Empty state: large 🧬 emoji (64px) centered + "No image selected" (16px, `var(--text-tertiary)`) + "Upload PNG or JPG MRI scan" (13px, `var(--text-tertiary)`)
- Buttons row:
  - `📷 Take Photo` — `var(--accent-primary)` filled
  - `🖼️ From Gallery` — outlined, `var(--accent-primary)` border & text
- Analyze button (inactive): `var(--bg-secondary)` filled, `var(--text-tertiary)` text, `🔍 Analyze MRI Scan`
  (active state): `var(--accent-primary)` filled, white, `🔍 Analyzing...` with spinner

---

### AI / MESSAGES CHAT SHEET

- Bottom sheet, same `border-radius` as timer sheet
- Tab bar: "Your doctor 👩‍⚕️" / "AI assistant 🤖"
  - Active tab: `var(--accent-primary)` underline + text color
  - Inactive: `var(--text-tertiary)`
- User bubble: `background: var(--accent-primary)`, white text, `border-radius: 18px 18px 4px 18px`
- AI bubble: `background: var(--bg-secondary)`, `var(--text-primary)`, `border-radius: 18px 18px 18px 4px`
- AI avatar: circular 36px, `var(--accent-primary-light)` bg, `🤖` emoji
- Input bar: `background: var(--bg-secondary)`, `border-radius: var(--radius-pill)`, `border: 1px solid var(--border-default)`
- Send button: `var(--accent-primary)`, circle, `➤`
- Mic button: outlined circle, `var(--text-secondary)`, `🎙️`
- **Reduce AI response text:** format AI replies as short bullet points with emoji prefixes. Never show raw markdown `**bold**` — parse and render properly.

---

### PROFILE / MENU DRAWER

- Slide-in from left (or top sheet)
- Avatar: 64px circle, gradient bg, white initials "SC"
- Name: 20px/700, `var(--text-primary)`
- Condition badge: pill chip, `var(--accent-secondary-light)` bg, `var(--accent-secondary)` text — "Chronic Migraine with Aura"
- "View profile →": `var(--accent-primary)`, 13px/600
- Menu items (full-width rows, 56px height, 16px padding):
  - ⚙️ Settings
  - 📋 Schedule appointment / With your linked doctors (12px, `var(--text-tertiary)`)
  - (divider)
  - 🚪 Sign out — `var(--accent-danger)`
- Each row: subtle bottom border `var(--border-default)`

---

### SCHEDULE APPOINTMENT SCREEN

- Title: "📋 Schedule appointment" with back arrow
- Section: "Book with your care team"
- Doctor dropdown: styled select, `var(--bg-card)`, `border: 1px solid var(--border-default)`, `border-radius: var(--radius-md)`, `👩‍⚕️` prefix emoji
- Date chip + Time chip (side by side): `background: var(--bg-secondary)`, `border: 1px solid var(--border-default)`, `border-radius: var(--radius-md)`, 📅 / ⏰ prefix emoji
- Visit type dropdown: same style as doctor dropdown
- Notes textarea: same card style, placeholder "📝 Notes for the clinic (optional)"
- CTA: `➤ Request appointment` — `var(--accent-primary)` full-width pill
- Past appointments section:
  - Card per appointment: `✅ COMPLETED` chip in `var(--accent-success-light)` / `var(--accent-success)`; `📅 UPCOMING` in `var(--accent-warning-light)` / `var(--accent-warning)`
  - Date: 13px, `var(--text-secondary)` / Visit type: 12px, `var(--text-tertiary)`

---

## UX PRINCIPLES TO APPLY

1. **Reduce cognitive load:** Cut every piece of body text by 50%. Translate disclaimers into icon + 3-word label. Users are in pain when using this — brevity is accessibility.

2. **Emoji as wayfinding:** Every section header gets a relevant emoji prefix. It aids scanning speed for users with migraine fog.

3. **Color = status at a glance:** Pain severity always maps to color (green → amber → red). Users should never have to read a number to understand urgency.

4. **Tap targets:** Minimum 44×44px for all interactive elements. Symptom cards (step 2 of logging) are full-width, making them easy to tap even during an attack.

5. **Progress feedback:** Logging flow shows a step indicator (dots or progress bar) at the top. Current step highlighted in `var(--accent-primary)`.

6. **Smooth transitions:** Use `react-native-reanimated` (or equivalent) for:
   - Bottom sheet slide-up
   - Screen transitions (slide, not fade)
   - Card press: `scale(0.97)` on press, release to `scale(1)`

7. **Empty states:** All empty states (no history, no MRI, new user) show a centered large emoji (80px) + 2-line message + optional CTA. No blank white screens.
   - History empty: `📅` + "No attacks logged yet" + "Your migraine-free days matter 💚"
   - MRI empty: `🧬` + "No scan uploaded"

8. **Loading states:** Replace spinners with emoji animation where possible (pulse animation on the relevant emoji) or a skeleton loader in `var(--bg-secondary)`.

9. **Accessibility:**
   - All interactive elements have `accessibilityLabel`
   - Color is never the only differentiator (always paired with emoji or text)
   - Font sizes never below 12px

10. **Spacing consistency:** Use the 8px grid exclusively. All padding/margin must be multiples of 4 or 8.

---

## IMPLEMENTATION NOTES

- Define all tokens in a central `theme.ts` file exporting both `lightTheme` and `darkTheme` objects
- Use `ThemeContext` with `useTheme()` hook throughout
- Replace all hardcoded hex colors with theme token references
- Wrap `StyleSheet.create()` calls inside a `useThemedStyles(styles)` hook that swaps token values
- All screens re-export from `screens/index.ts` — no structural refactoring needed
- Emoji: use React Native's `<Text>` element for emoji rendering (cross-platform safe), never image assets
- For decorative background emoji clusters: use `position: 'absolute'`, `opacity: 0.1`, `fontSize: 56`, `pointerEvents: 'none'`

---

## DO NOT CHANGE

- Screen names and navigation routes
- All data models, API calls, state management logic
- Button labels (text content — only style them)
- Form field names and validation logic
- The bottom navigation tab order (Home / Stats / [+] / History / MRI)
- Chart data and calculation logic
- The calendar component logic (only its visual style)
