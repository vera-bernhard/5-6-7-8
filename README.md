# Audio Timestamp Trainer - Flutter

A dance practice helper app: load audio, create named timestamps, and jump to
choreography sections quickly.

## Features

- Import audio files (`mp3`, `wav`, `m4a`, `aac`, `ogg`)
- Playback with seek controls and a horizontal waveform-style timeline
- Create named timestamps at the current playback position
- Tap timestamp: jump to marker using selected default lead-in (`0s`, `3s`, `5s`)
- Long-press timestamp: choose lead-in per jump (`0s`, `3s`, `5s`)

## Run

Requires Flutter SDK.

```bash
flutter pub get
flutter run
```

Run on a specific device/platform:

```bash
flutter devices
flutter run -d chrome
```

## Build
```bash
flutter build apk --release
```

Build for web/PWA:

```bash
flutter build web --release
```

Deploy the generated `build/web` folder over HTTPS to enable full installable PWA behavior.


## Tech Stack

- State management: Riverpod
- Audio engine: just_audio
- File picker: file_picker
