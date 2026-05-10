# Painpal

Painpal is a patient-facing Flutter mobile application for migraine tracking, symptom logging, MRI scan analysis, and simple analytics. It is designed to help patients understand patterns in their condition without overwhelming them with medical jargon.

## What the app does

- Logs migraine attacks using a structured symptom form.
- Uploads brain MRI scans for backend classification.
- Stores history locally for offline-friendly review.
- Shows simple analytics and AI-style insights to highlight trends.
- Provides a built-in AI chat assistant with text and voice input.

## Designed for

- Patients who want a simple way to track migraines over time
- Non-technical users who need large touch-friendly controls
- Users who may be in pain and need a clear, low-friction interface

## App structure

Painpal uses a mobile-first, card-based layout with calm healthcare colors and a bottom navigation bar.

### Bottom navigation tabs

1. **Overview** — app introduction and quick start
2. **Log attack** — enter migraine symptoms and submit them
3. **MRI upload** — pick or capture a scan for analysis
4. **History** — review saved migraine and MRI records
5. **Analytics** — view trends, triggers, medication effectiveness, and AI insights
6. **Settings** — configure API connection and patient identity

The navigation includes an **Analytics** icon (`Icons.analytics_outlined`) in the bottom bar.

## Main screens

### 1) Overview screen

The overview screen gives a short introduction to the app and the main user flows.

- Welcome card with the Painpal identity
- Feature cards for migraine logging, MRI upload, history, and settings
- Quick-start steps for first-time users

This screen is useful as a landing page for new users.

### 2) Log Migraine Attack screen

This is the core data-entry screen for migraine tracking.

#### What users can enter

- Duration in hours
- Frequency per month
- Location: unilateral or bilateral
- Pain character: throbbing or pressure
- Pain intensity on a 1–10 slider
- Associated symptoms:
  - Nausea
  - Vomiting
  - Sound sensitivity
  - Light sensitivity
  - Visual disturbances
  - Sensory issues
- Neurological symptoms:
  - Speech difficulty
  - Slurred speech
  - Dizziness / vertigo
  - Ringing in ears
  - Hearing loss
  - Double vision
  - Visual field defect
  - Loss of coordination
  - Loss of consciousness
  - Abnormal sensations
- Optional details:
  - Age
  - Attack ID

#### What happens when the user submits

1. The form validates required fields.
2. The app reads the API base URL from Settings.
3. It sends the migraine attack to the backend.
4. The returned predicted migraine type and summary are shown in result cards.
5. The final record is saved locally in SQLite.
6. Any draft entry is cleared from shared preferences.

#### Draft support

Users can save the form as a local draft and continue later. Drafts are stored in shared preferences and restored when the screen opens again.

### 3) MRI upload screen

This screen lets users upload a brain MRI scan for analysis.

#### Supported input methods

- Take a photo with the camera
- Select an image from the gallery

#### What happens after selection

- The selected image is copied into the app documents directory
- A preview is shown immediately
- The scan can then be submitted for backend prediction

#### Result display

- Prediction result: example values include `Tumor` or `Non-tumor`
- Confidence score is shown as a percentage
- The scan is saved locally to history

### 4) History screen

The history view lists previously saved records in two sections:

- Migraine attack history
- MRI scan history

Each migraine card shows:

- Attack number
- Timestamp
- Duration
- Intensity
- Frequency
- Location
- Predicted migraine type, if available

Each MRI card shows:

- Scan number
- Timestamp
- Preview thumbnail, if the file still exists locally
- Prediction result
- Confidence score

### 5) Analytics screen

The analytics screen turns stored migraine records into easy-to-read insights.

#### Summary card

Shows at a glance:

- Total migraines in the selected period
- Average pain intensity
- Most common trigger
- Short AI-style summary sentence

#### Migraine trends

- Line chart of migraine frequency over time
- Week / Month toggle
- Spike markers for days or periods with increased activity

#### Pain and duration analysis

- Pain intensity distribution using low / medium / high bars
- Average duration per attack

#### Trigger insights

- Trigger breakdown with icons and percentages
- Examples include stress, sleep issues, and food

#### Medication effectiveness

- Medication names with approximate success rate
- Monthly usage counts
- Warning card if use appears high enough to suggest overuse

#### AI insights

- 2–3 short, readable insight cards
- Pattern detection
- Risk reminders
- Aura-related pattern suggestions

#### Filtering options

- Last 7 days
- Last 30 days
- Last 3 months

#### Loading behavior

The analytics screen uses skeleton placeholders while data loads.

### 6) Settings screen

The settings screen stores app configuration locally.

#### Configurable values

- **API Base URL** — backend server address
- **Patient ID** — optional identifier used in requests and local records

#### Also includes

- Connection reminder
- Educational disclaimer
- App information section

## AI assistant

Painpal includes a floating chat button that opens a conversational assistant.

### Chat features

- Text input for questions and guidance
- Voice input through speech recognition
- Spoken responses through text-to-speech
- Friendly migraine-focused onboarding message

This is useful for quick support without leaving the current screen.

## Data flow

Painpal uses both local storage and a backend API.

### Local storage

- `shared_preferences`
  - API base URL
  - Patient ID
  - Migraine draft form data
- `sqflite`
  - Migraine attack history
  - MRI scan history

### Backend submission

#### Migraine submission

The app posts migraine data to:

```text
/api/summary
```

#### MRI submission

The app uploads an image to:

```text
/api/mri/predict
```

### Local persistence behavior

- Submitted migraine attacks are saved in SQLite after the backend response returns
- MRI predictions are also stored locally after successful upload
- History is shown in reverse chronological order

## Environment setup

The app loads environment variables from a `.env` file at startup.

### Current runtime expectation

The existing code loads:

```text
.env
```

If your backend or AI services require additional keys, add them to the `.env` file and ensure the file is bundled correctly for local development.

## Required packages and capabilities

The Flutter app uses:

- `http` and `dio` for API communication
- `image_picker` for camera and gallery selection
- `path_provider` for local file storage
- `shared_preferences` for settings and drafts
- `sqflite` for offline history
- `google_generative_ai` for AI assistant capabilities
- `flutter_tts` for spoken responses
- `flutter_dotenv` for environment loading

## Permissions

Depending on platform and features used, the app may require:

- Camera access
- Photo gallery access
- Microphone access
- Speech recognition permissions

## Sample data schema

Migraine records use this exportable schema:

```text
patient_id, attack_id, Duration, Frequency, Location, Character, Intensity, Nausea, Vomit, Phonophobia, Photophobia, Visual, Sensory, Dysphasia, Dysarthria, Vertigo, Tinnitus, Hypoacusis, Diplopia, Defect, Ataxia, Conscience, Paresthesia, DPF, Type
```

## UX guidelines used in the app

- Single-column mobile layout
- Large readable typography
- Card-based sections
- Soft healthcare-friendly colors
- Touch-friendly buttons and toggles
- Minimal steps to log symptoms
- Clear loading and empty states

## Disclaimers

- This app is intended for education and self-tracking only.
- Predictions are not medical diagnoses.
- MRI and migraine outputs should not be treated as emergency medical advice.
- Users should consult qualified healthcare professionals for diagnosis and treatment.

## Quick start

```sh
flutter pub get
flutter run
```

## Troubleshooting

- If the app says the API base URL is missing, open **Settings** and enter your backend address.
- If MRI upload fails, confirm that the backend endpoint is reachable and the selected image is valid.
- If the analytics screen looks empty, log a few attacks first so the charts can populate with real data.
- If voice chat does not work, check microphone and speech permissions on the device.

## Project summary

Painpal is a calm, patient-friendly migraine companion that combines structured symptom logging, MRI scan review, local history, analytics, and AI assistance in one mobile app.
