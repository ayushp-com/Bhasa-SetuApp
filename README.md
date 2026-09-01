# Bhasa-Setu

Bhasa-Setu is an open-source Flutter mobile application designed to empower teachers and students in multilingual and tribal learning environments by providing localized, instant translations into regional and tribal languages including Santhali, Mundari, and Ho.

## Key Features

* **Offline-First SQLite Core**: Pre-loaded with comprehensive dictionary assets and school-level vocabulary for instantaneous, zero-latency lookups across Santhali, Mundari, and Ho without requiring an active internet connection.
* **Multi-Vernacular Support**: Seamless text mapping between English, Hindi, and indigenous tribal languages.
* **Hybrid Fallback Engine**: Combines local relational database lookups with dynamic translation routing to guarantee smooth phrase and sentence translation.
* **Classroom Pedagogical Tools**: Integrated speech-to-text input, text-to-speech pronunciation, and one-tap PDF export utilities for lesson materials.

## Tech Stack

* **Framework**: Flutter / Dart
* **Local Storage**: `sqflite` for high-performance offline database management.
* **Speech & Audio**: `flutter_tts`, `speech_to_text`, and `sherpa_onnx`.
* **Export Utilities**: `pdf` and `printing`.
