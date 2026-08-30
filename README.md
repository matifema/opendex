<h1 align="center">OpénDex</h1>

<p align="center"><strong>A Gen 1 Pokédex for whatever is in front of the camera.</strong></p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.4%2B-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Gemini-AI-purple?logo=googlegemini" alt="Gemini AI">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

---

Point the camera at a person, a pet, a coffee mug, or anything else and Opéndex turns it into a Gen 1-style Pokémon: name, types, stats, moves, and a walking sprite.

The chunky pixels are the point. Sprites are generated small, then scaled with nearest-neighbor so they stay blocky instead of getting smoothed into mush. It is meant to look like a Game Boy Pokédex entry, not a high-res illustration.

There is no account and no backend. The phone talks to the Gemini API and stores the collection locally.

---

## Example

<table align="center">
  <tr>
    <td align="center" width="220">
      <strong>Original photo</strong><br>
      <img src="docs/screenshots/octolume-photo.png" alt="Original photo" width="200">
    </td>
    <td align="center" width="100" valign="middle">
      <strong style="font-size: 48px;">&#8594;</strong>
    </td>
    <td align="center" width="280">
      <strong>Generated creature</strong><br>
      <img src="docs/screenshots/octolume-animated.gif" alt="Octolume sprite animation" width="256">
    </td>
  </tr>
</table>

<p align="center"><em>Octolume, a Water / Light type, generated from a photo of a toy octopus.</em></p>

---

## Screenshots

<p align="center">
  <img src="docs/screenshots/screenshot3.png" alt="App screenshot 3" width="200">
  <img src="docs/screenshots/screenshot2.png" alt="App screenshot 2" width="200">
  <img src="docs/screenshots/screenshot1.png" alt="App screenshot 1" width="200">
</p>

---

## Features

- **Photo in, Pokémon out** — people, objects, pets, whatever is in the frame
- **Gen 1 presentation** — dual types, HP/Attack/Defense/Speed, flavor text, and four moves
- **Intentional pixelation** — 4-frame walk cycle generated small and nearest-neighbor scaled; blur is a bug, chunks are the look
- **Pokédex shell** — D-pad, LCD-style screen, VT323
- **On-device library** — collection persists locally; release anything you do not want to keep
- **No backend** — Gemini API from the phone only

---

## More Creatures

<p align="center">
  <img src="docs/screenshots/ichthyosavant-animated.gif" alt="Ichthyosavant sprite" width="128">
  <img src="docs/screenshots/rubytrunk-animated.gif" alt="Rubytrunk sprite" width="128">
</p>

<p align="center"><em>Ichthyosavant (Nature / Arcane) and Rubytrunk (Earth / Arcane)</em></p>

---

## Download

| Platform | Link |
|----------|------|
| Android  | [app-release.apk](https://github.com/matifema/opendex/releases/latest/download/app-release.apk) |

Scan the QR code or tap the link above to download the latest APK directly to your Android device.

> iOS is not yet supported due to Gemini image generation limitations on the SDK version used.

---

## How It Works

```
[Camera] --> [Gemini Text] --> [Creature Spec]
                 |
                 +-> Name, Types, Stats, Flavor Text
                 +-> Visual description + palette
                              |
                              v
                       [Gemini Image]
                              |
                              +-> 256x64 sprite sheet (4 frames)
                              |
                              v
                       [Post-Processing]
                              |
                              +-> White-to-transparent conversion
                              +-> Nearest-neighbor resize
                              |
                              v
                       [Move Database]
                              |
                              +-> 4 moves based on types
```

The app sends your photo to `gemini-3.1-flash-lite-preview` which returns a JSON creature spec. That spec is then sent to `gemini-3.1-flash-image-preview` to generate the pixel art. The raw sprite goes through chrominance-aware alpha masking and nearest-neighbor resize to produce crisp transparent PNGs.

### Cost per creature

Pricing based on [Google Gemini API](https://ai.google.dev/gemini-api/docs/pricing) (June 2026).

| Step | Model | Input tokens | Output tokens | Free tier | Paid tier |
|------|-------|-------------|---------------|-----------|-----------|
| Analysis | `gemini-3.1-flash-lite` | ~2,200 text + ~260 image | ~600 JSON | $0 | ~$0.0015 |
| Sprite sheet | `gemini-3.1-flash-image` | ~3,000 text | ~200 image | -- | ~$0.0135 |
| **Total** | | | | **~$0.012** | **~$0.015** |

The analysis model is free on the free tier, making image output tokens ($60/1M) the dominant cost. On the paid tier both steps together still come out to roughly 1.5 cents per creature. The sprite sheet is only 256 x 64 pixels so it stays well under the 512 px pricing tier.

---

## Contributing

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.4 or later
- Android SDK (for Android builds) or Xcode (iOS, currently limited support)
- A [Gemini API key](https://aistudio.google.com/apikey)

### Setup

```bash
git clone https://github.com/matifema/opendex.git
cd opendex/OpénDex
flutter pub get
```

### Run (debug)

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

You can also enter the API key inside the app's Settings screen.

### Build (release APK)

```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=your_key_here
```

The APK is output to `build/app/outputs/flutter-apk/app-release.apk`.

### Project structure

```
OpénDex/lib/
  config.dart                  -- API key from dart-define
  main.dart                    -- App entry point, theming
  models/                      -- Creature, Stats, Move data classes
  pages/
    home_page.dart             -- Camera, generation flow, navigation
    settings_page.dart         -- API key input and preferences
  services/
    ai/
      gemini_service.dart      -- Gemini API client (analysis + image gen)
      image_processor.dart     -- White-to-transparent + resize pipeline
      move_database.dart       -- Gen 1 move pool with type-based selection
    storage/                   -- SharedPreferences, file-based persistence
  widgets/
    home/
      pokedex_screen.dart      -- LCD display with creature stats and sprite
      pokedex_header.dart      -- Title bar and species counter
      control_panel.dart       -- Capture button and D-pad
    capture_animation.dart     -- Pokeball spinner during generation
    dex_open_animation.dart    -- Mechanical opening animation
```

### Architecture notes

The generation pipeline is stateless: each photo triggers a fresh Gemini call. The only state stored locally is the creature library (serialized as JSON via `shared_preferences` and sprite sheets saved as PNG files). The API key is also stored in `shared_preferences` if entered through Settings.

The image generation uses raw HTTP (not the SDK) because the `google_generative_ai` 0.4.7 SDK cannot parse `inlineData` parts in model responses. The HTTP client handles both the analysis and image endpoints, with one automatic retry on transient failures.

### Dependencies

| Package | Purpose |
|---------|---------|
| `google_generative_ai` ^0.4.7 | Gemini text generation SDK |
| `http` ^1.5.0 | Raw HTTP for Gemini image generation |
| `image` ^4.5.4 | Pixel-level image processing |
| `image_picker` ^1.1.2 | Camera and gallery access |
| `shared_preferences` ^2.2.2 | Local persistence |
| `path_provider` ^2.1.3 | File system paths |
| `google_fonts` ^6.2.1 | VT323 pixel font |

---

## Disclaimer

Opéndex is a fan-made project not affiliated with, endorsed by, or connected to The Pokémon Company, Nintendo, Game Freak, or Creatures Inc. All generated creatures are original creations. Generated assets should not be used commercially.
