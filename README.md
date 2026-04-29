# PokéSnap PixelMon (Flutter)

Capture one or more photos of an animal with the device camera, generate a 1st‑gen Pokémon–style pixel creature with a transparent PNG, and auto-generate a name and stats.

All AI generation runs **client-side** via the Gemini API — no backend server required.

---

## Setup (Linux/Ubuntu)

1) Install Flutter SDK and Android tooling
- Install Flutter via snap:
  - `sudo snap install flutter --classic`
- Enable Flutter SDK:
  - `flutter --version`
  - `flutter doctor`
- Install Android Studio or SDK tools if prompted by `flutter doctor` and accept licenses:
  - `flutter doctor --android-licenses`

2) Create platform scaffolding
- Navigate to the app folder:
  - `cd pokegen_app`
- If you did not create a Flutter project yet in this folder, initialize:
  - `flutter create .`
- Fetch dependencies:
  - `flutter pub get`

3) Configure environment
- Provide your Gemini API key via `--dart-define` at run time:
  - `GEMINI_API_KEY=<your gemini key>`
- Example run:
  - `flutter run --dart-define=GEMINI_API_KEY=sk-...`
- Or enter the key in the app's Settings screen at runtime.

4) Platform permissions
- Android: Edit `android/app/src/main/AndroidManifest.xml` and add within `<manifest>`:
  ```
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
  ```
  Inside `<application>` ensure a FileProvider if you customize camera storage.
- iOS: In `ios/Runner/Info.plist`, add:
  ```
  <key>NSCameraUsageDescription</key>
  <string>We use the camera to capture animal photos.</string>
  <key>NSPhotoLibraryAddUsageDescription</key>
  <string>We save your generated pixel monsters.</string>
  ```

---

## How it works

- **Capture Photos**: Uses `image_picker` to take one or more photos.
- **Analyze & Generate Stats**: Sends the photo + description to `gemini-3.1-flash-lite-preview` (multimodal) to get creature stats, types, flavor text, and a visual spec — all as structured JSON. Includes a safety check that rejects human photos.
- **Generate Sprite Sheet**: Sends the visual spec to `gemini-3.1-flash-image-preview` to produce a 4-frame pixel art sprite sheet (128×32 px).
- **Post-Process**: Converts the white background to transparent and resizes to exactly 128×32 using nearest-neighbor interpolation (crisp pixels).
- **Move Selection**: Assigns 4 Gen 1-style moves based on the creature's types (type-matching damaging + status + coverage).
- **Storage & Animation**: Saves the PNG locally with a Pokéball-themed capture animation overlay during generation.

Files of interest:
- `pokegen_app/lib/pages/home_page.dart` – camera flow and UI
- `pokegen_app/lib/services/ai/gemini_service.dart` – Gemini API calls (analysis + image generation)
- `pokegen_app/lib/services/ai/image_processor.dart` – white→transparent + resize post-processing
- `pokegen_app/lib/services/ai/move_database.dart` – Gen 1 move database + type-based selection
- `pokegen_app/lib/models/pokemon_models.dart` – data models
- `docs/data-models.md` – Mermaid diagrams
- `docs/prompts.md` – replicated prompts

---

## AI Models

| Step | Model | Purpose |
|------|-------|---------|
| Analysis | `gemini-3.1-flash-lite-preview` | Multimodal (photo + text) → JSON stats, types, visual spec, safety check |
| Image | `gemini-3.1-flash-image-preview` | Text prompt → 4-frame pixel art sprite sheet (PNG) |

Both models are accessed via the `firebase_ai` Dart SDK using `FirebaseAI.googleAI()` (Gemini Developer API).

---

## Disclaimer

This project is fan-themed and not affiliated with or endorsed by The Pokémon Company, Nintendo, Game Freak, or Creatures Inc. Use responsibly and respect IP when distributing assets.
