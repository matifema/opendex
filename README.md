# PokéSnap PixelMon (Flutter)

Capture one or more photos of an animal with the device camera, generate a 1st‑gen Pokémon–style pixel creature with a transparent PNG, and auto-generate a name and stats.

This repo includes:
- `pokegen_app/` – a Flutter app (lib/ + pubspec.yaml)
- `docs/` – Mermaid data models and replicable prompts

Note: Image generation is delegated to your own HTTP backend (`API_BASE_URL`) to securely call your chosen image model. Text generation uses Gemini via the client SDK (`GEMINI_API_KEY`).

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
- Provide your keys via `--dart-define` at run time:
  - `GEMINI_API_KEY=<your gemini key>`
  - `API_BASE_URL=<your backend base url>`, e.g., `https://api.example.com`
- Example run:
  - `flutter run --dart-define=GEMINI_API_KEY=sk-... --dart-define=API_BASE_URL=https://api.example.com`

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

- Capture Photos: Uses `image_picker` to take one or more photos.
- Generate Pixel Art PNG: Sends photos + a strict prompt to your backend (`/generate/pixelmon`) which calls an image model to return a transparent PNG.
- Generate Name & Stats: Uses Gemini (client-side) to produce JSON with name, types, flavor text, and base stats.
- Storage & Animation: Saves PNG locally with a Pokéball-themed capture animation overlay during generation.

Files of interest:
- `pokegen_app/lib/pages/home_page.dart` – camera flow and UI
- `pokegen_app/lib/services/ai/*` – prompts and AI services
- `pokegen_app/lib/models/pokemon_models.dart` – data models
- `docs/data-models.md` – Mermaid diagrams
- `docs/prompts.md` – replicated prompts

---

## Backend contract (image generation)

POST `${API_BASE_URL}/generate/pixelmon`
- Multipart form-data:
  - `photos`: one or more image files
  - `prompt`: string
  - `size`: integer (e.g., 256)
- Returns:
  - `200 OK` with raw PNG bytes (transparent background, square canvas)

Security: Keep model API keys on the server. Validate inputs and size limits server-side.

---

## Disclaimer

This project is fan-themed and not affiliated with or endorsed by The Pokémon Company, Nintendo, Game Freak, or Creatures Inc. Use responsibly and respect IP when distributing assets.
