# Painpal

Patient-side mobile app for migraine tracking and MRI classification.

## Features
- Log migraine attacks with the required symptom schema.
- Upload MRI scans for tumor vs non-tumor prediction.
- View prediction results and local history (offline-ready).
- Store API base URL and optional patient ID.

## API configuration
Set the backend base URL (for example, `https://example.com`) in the **Settings** tab.

## Data schema (exportable)
`patient_id, attack_id, Duration, Frequency, Location, Character, Intensity, Nausea, Vomit, Phonophobia, Photophobia, Visual, Sensory, Dysphasia, Dysarthria, Vertigo, Tinnitus, Hypoacusis, Diplopia, Defect, Ataxia, Conscience, Paresthesia, DPF, Type`

## Disclaimer
This app is for educational and self-tracking purposes only. Predictions are not medical diagnoses. Users should consult healthcare professionals for diagnosis and treatment.

## Run
```sh
flutter pub get
flutter run
```

