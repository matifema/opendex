# Opéndex

Capture an animal photo → generate a unique 1st‑gen Pokémon–style pixel creature with transparent PNG sprite sheet, auto-generated name, stats, types, and flavor text. All running entirely on-device via Google's Gemini API.

<div align="center">

**Flutter · Gemini AI · No Backend Required**

</div>

---

## Features

- **Photo Capture** — Take a photo of any animal
- **AI Analysis** — Get creature stats (HP, Attack, Defense, Speed), dual types, species name, and flavor text from `gemini-3.1-flash-lite-preview`
- **Sprite Generation** — Produce a 4-frame walking animation sprite sheet via `gemini-3.1-flash-image-preview`
- **Post-Processing** — White-to-transparent conversion + nearest-neighbor resize for crisp pixel art
- **Move Selection** — Auto-assigns 4 Gen 1-style moves based on creature types
- **Pokedex UI** — Retro-styled device with D-pad navigation (left/right browsing, up/down scrolling), LCD display, and persistent library
- **Creature Release** — Delete creatures you no longer want from your collection
- **Full Client-Side** — No server needed. API key passed at runtime or stored in settings

## Development Quick Start

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.4.0`)
- Android SDK / Xcode (for mobile target)

### Setup

```bash
cd pokegen_app
flutter pub get
```

### Run

```bash
# Via CLI flag
flutter run --dart-define=GEMINI_API_KEY=your_key_here

# Or enter the key inside the app's Settings screen
flutter run
```

## Architecture

```
pokegen_app/lib/
├── model/         # Data models (Creature, Stats, Move, etc.)
├── pages/
│   ├── home_page.dart    # Main camera flow and navigation shell
│   └── settings_page.dart# API key input & preferences
├── services/
│   ├── ai/
│   │   ├── gemini_service.dart       # Gemini API client — analysis + image gen
│   │   ├── image_processor.dart      # White-bg → transparent + resize pipeline
│   │   └── move_database.dart        # Gen 1 move pool + type-based selection
│   └── storage/                        # Local persistence (shared_preferences, FileService, PokedexStorage)
├── widgets/
│   ├── home/
│   │   ├── pokedex_screen.dart     # Device body with LCD screen + controls
│   │   ├── pokedex_header.dart      # Title bar + species counter
│   │   └── control_panel.dart       # Capture button + d-pad widget
│   └── sprite_sheet_animation.dart  # Animated sprite playback widget
└── utils/
    └── constants.dart           # Typedefs for dart-define API keys & config
```

## Generation Pipeline

```
[Photo] + [Source Description] → Gemini Multimodal (gemini-3.1-flash-lite-preview)
                     │
                     ├→ Animal detection (rejects non-animal photos)
                     ├→ Creature name (~inspired by subject + elemental fusion)
                     ├→ Type pair (e.g., Fire / Psychic) from 10-type pool
                     ├→ Stats (HP, Attack, Defense, Speed; range 30–100)
                     ├→ Flavor text
                     ├→ Rich creature description (body shape, colors, effects)
                     └→ Visual spec (palette hexes, 4-frame idle loop breakdown)
                                 │
                                 ↓
             [Creature Description + Visual Spec] → Gemini Image (gemini-3.1-flash-image) via REST API
                                 │
                                 └→ 4-frame sprite sheet (256×64 px PNG, solid white bg)
                                          ↓
                          Image Post-Processing (image_processor.dart)
                                          │
                                          ├→ Chrominance-aware flood-fill from canvas edges → alpha mask
                                          ├→ Morphological close (dilate + erode) for edge smoothing
                                          ├→ Saturation guard preserves character highlights
                                          └→ Nearest-neighbor resize to 256×64
                                          ↓
                              256×64 transparent walking-sprite sheet
                              

                           [Type Pair] → Move Database
                                          │
                                          └→ 4 moves: 2× STAB + 1× Coverage + 1× Status
```

## Project Structure

| Path | Purpose |
|------|---------|
| `docs/data-models.md` | Mermaid diagrams of Creature/Stats/Move schema |
| `docs/prompts.md` | Replicated system prompts used in generation |

## Dependencies

| Package | Version | Use |
|---------|---------|-----|
| `google_generative_ai` | ^0.4.7 | Gemini API client |
| `image_picker` | ^1.1.2 | Camera/photo picker |
| `image` | ^4.5.4 | Pixel processing (transparency, resize) |
| `shared_preferences` | ^2.2.2 | Persistence (API key, creature registry) |
| `path_provider` | ^2.1.3 | Storage directory resolution |
| `google_fonts` | ^6.2.1 | Custom fonts (VT323 pixel font) |

## Disclaimer

Opéndex is a fan-made project not affiliated with, endorsed by, or connected to The Pokémon Company, Nintendo, Game Freak, or Creatures Inc. All generated creatures are original creations inspired by Gen 1 aesthetics. Generated assets should not be used commercially.
