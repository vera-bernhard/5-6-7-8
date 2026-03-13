# 5-6-7-8

<img src="assets/icon/5678_logo_square.png" alt="5-6-7-8 App Icon" width="140" />

available under: [vera-bernhard.github.io/5-6-7-8](https://vera-bernhard.github.io/5-6-7-8/)

5-6-7-8 is a Flutter app for music-based training and routines, such as team aerobics, dance, gymnastics, rhythmic gymnastics, cheerleading, figure
skating, artistic swimming, and show groups. It lets you build a small song
library, add named timestamps to songs, and replay single timestamps or whole
timestamp ranges with an optional lead-in.

## Current Functionality

- Import audio files with these extensions: `mp3`, `wav`, `m4a`, `aac`, `ogg`
- Name each imported song before adding it to the library
- Persist songs and timestamps locally on device or in browser storage for the
	PWA
- Browse a library of saved songs
- Rename or delete songs from the library
- Open a song in the player view
- Play, pause, and seek through the track
- Use a generated waveform-style seek area for scrubbing
- Add timestamps with a name and editable time value
- Store unnamed timestamps as well
- Replay a timestamp with a configurable lead-in of `0s`, `1s`, `3s`, or `5s`
- Long-press timestamps to mark a contiguous segment
- Replay the selected segment, again with the configured lead-in
- Mark timestamps as shuffle-enabled
- Play a random shuffle-enabled segment with the `Random` button
- Delete individual timestamps

## Storage

Songs and timestamps are stored locally using Hive.

- The PWA stores data in browser storage (IndexedDB)
- For an installable PWA, deploy over HTTPS so the app can be installed and use
	persistent browser storage

## PWA: What and Why

A PWA (Progressive Web App) is a website that can be installed like an app and
launched from the home screen/app launcher.

Why this makes sense for 5-6-7-8:

- No app store release is required for each update
- Works on Android, iOS, and desktop browsers from one deployment
- Fast access during training sessions (open from home screen like an app)
- Offline use is possible for already loaded app files and locally stored songs
	and timestamps
- Local-first storage is practical for routine/music practice without cloud
	setup

## Offline Functionality

The app is designed to work offline after songs are already in local storage.

- Playback and timestamp workflows work without network access once audio is
	imported
- Song/timestamp changes are stored locally and remain available offline
- The app has no cloud sync; data stays on the current device/browser profile
- For PWA use, first load/install over HTTPS while online, then offline use is
	available for locally stored content

## Run

Requires a Flutter SDK installation.

```bash
flutter pub get
flutter run -d chrome
```

## Build

Build for PWA/web:

```bash
flutter build web --release
```

## Notes

- The waveform display is a generated visual seek aid, not an analyzed audio
	waveform
- The app currently keeps audio bytes with each stored song, which makes the
	web/PWA build self-contained but can increase browser storage usage for large
	libraries

## Tech Stack

- Flutter
- Audio playback: just_audio
- Local storage: hive_flutter
- File picking: file_picker
