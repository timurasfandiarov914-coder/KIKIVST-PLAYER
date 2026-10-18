# KIKI VST PLAYER

Open-source music player foundation built with Flutter and Dart. This first milestone establishes the app shell, catalog-search contracts, stream-resolution contracts, a real queue-based audio handler, and automated Dart checks.

## Current state

- Real playback engine based on just_audio and audio_service.
- Queue, media metadata, playback controls, and media-session state.
- Catalog adapters are not wired yet. Search results are never fabricated; the UI reports when no providers are configured.
- No stream ripping, DRM bypass, fake API endpoints, embedded credentials, or hard-coded demo tracks.

## Stack

- Flutter / Dart
- just_audio for playback and queue loading
- audio_service for background playback and system media controls
- audio_session for audio focus and interruptions
- GitHub Actions for formatting, analysis, and tests

## Run locally

Install the current stable Flutter SDK, then from the repository root:

    flutter create --platforms=android --project-name=kikivst_player --org=app.kiki .
    flutter pub get
    flutter run

The flutter create command adds generated Android platform scaffolding to this source-first repository. Keep existing source files when Flutter asks about already-present project files.

For Android background playback, verify the generated manifest against the audio_service setup guide and ensure the foreground media-playback service and media-button receiver are registered.

## Project layout

- lib/core/models: normalized catalog and playable-track models.
- lib/features/catalog: provider-independent search contract and concurrent search coordinator.
- lib/features/resolver: provider-independent stream-resolution contract and resolver composition.
- lib/features/player: queue-based audio handler and player UI.
- test: tests for catalog search behavior.

## Provider integration policy

Each catalog adapter must use an API and playback flow that the source permits. Metadata availability does not automatically grant permission to resolve or play that source's audio elsewhere. Provider credentials must be supplied through a supported authentication flow or build-time configuration, never committed to this repository.

## Development checks

    dart format --output=none --set-exit-if-changed lib test
    flutter analyze --fatal-infos
    flutter test

The first PR is a foundation, not a finished catalog aggregator. Provider adapters and source-specific playback resolution will be added in separate, testable changes.
