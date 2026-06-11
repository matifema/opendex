# Changelog

## [0.1.0] -- 2025-06-11

### Added
- Pokédex mechanical opening animation (two-halves slide apart revealing LCD scanner screen)
- Custom pokeball icon rendered with `CustomPainter` (replaces Material `catching_pokemon` icon)
- Glow and flash effects around the pokeball during generation
- Keyboard arrow up/down navigation for scrolling the creature detail view
- Scanline overlay on the LCD screen during opening animation
- Auto-retry on sprite sheet generation when the model returns text-only

### Changed
- Removed animal detection filter -- Opéndex now generates a creature from any photo you take
- Camera opens directly on capture (no more camera/gallery choice dialog)
- `CaptureAnimation` redesigned with glowing pokeball + "GENERATING..." text
- Font sizes tightened across the app; `debugShowCheckedModeBanner` hidden
- Elevation and border-radius theming applied globally to buttons, cards, and dialogs
- Error messages shown to users are now friendly ("please try again") instead of raw exceptions
- Stats parsing now uses `CreatureStats.fromJson` instead of manual clamping

### Removed
- `NoAnimalDetectedException` class and animal detection logic
- `prompts.dart` (prompts are now defined inline in `gemini_service.dart`)
- Camera/gallery source chooser dialog

### Fixed
- JSON parser now strips markdown code fences from Gemini responses
- `FormatException` caught during JSON decode, surfaced as a clean `StateError`
