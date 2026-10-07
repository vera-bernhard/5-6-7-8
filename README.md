# 5-6-7-8

<img src="assets/icon/5678_logo_square.png" alt="5-6-7-8 App Icon" width="140" />

available under: [vera-bernhard.github.io/5-6-7-8](https://vera-bernhard.github.io/5-6-7-8/)

5-6-7-8 is a practice app for music-based training and routines, such as team
aerobics, dance, gymnastics, rhythmic gymnastics, cheerleading, figure skating,
artistic swimming and show groups. You import your routine music, mark the
important moments with timestamps, and replay single parts or whole sections
as often as you need, with a count-in before and some extra time after.

## What the app can do

### Song library
- Import audio files (`mp3`, `wav`, `m4a`, `aac`, `ogg`, `mid`, `midi`) and
  give each song a name
- Rename and delete songs
- Everything is stored on your device: no account, no cloud, works offline

### Player
- Play, pause and seek by tapping or dragging on the waveform
- The waveform shows the real loudness of the music, so you can see where one
  song of a mix ends and the next one starts (web app)
- A BPM band above the waveform shows each song of a mix with its tempo, for
  example `128 | 143 BPM | 125`. The song that is currently playing is
  highlighted and its field also shows the unit, growing over its neighbours
  if needed. The tempo of a short song may reach into its neighbours too, so
  it stays readable. Tap the band to see a chart of the BPM over the song and
  the exact times and BPM of each section (web app)
- Change the playback speed between 0.8x and 1.2x to practise slower or faster

### Timestamps and segments
- Save a timestamp at the current position, with an optional name and an
  editable time
- Replay from any timestamp
- Long-press timestamps to mark a segment and replay just that part. A segment
  runs from the first marked timestamp to the timestamp after the last marked
  one.

### Lead-in and lead-out
- **Lead-in** (0–15 s): replay starts a few seconds before the timestamp, so
  you have time to get into position
- **Lead-out** (0–15 s): segments keep playing a few seconds past their end
- If the lead-in would start before the beginning of the song, the app waits
  the missing seconds in silence and shows a "Starting in 3… 2… 1" countdown.
  The same happens with an "Ending in…" countdown when a lead-out reaches past
  the end of the song. Press Stop to cancel a countdown.

### Random practice
- Mark timestamps for random practice
- The shuffle button plays a random marked segment, and never the same one
  twice. The ring around the button shows how many are left. Long-press the
  button to start over.

### Language
- English and German. The app follows the language of your device, and uses
  English for other languages
- To choose a language yourself, tap the 🌐 button below **Upload Song** in
  the library. **System language** follows the device again.

### Imprint
- The **About** button (**Impressum** in German) next to the language button
  shows the developer, who the app was made for, a note that the app is a
  beta version, a link to this repository and the tools it was built with.

## Using it as an app (PWA)

The web version is a PWA (Progressive Web App): open it once in the browser
and install it to your home screen, then it starts like a normal app.

- No app store needed; updates arrive automatically
- Works on Android, iOS and desktop from one deployment
- Works offline once the app is loaded and your songs are imported
- Data stays in the browser profile on that device; there is no sync between
  devices

### Install on iPhone / iPad
1. Open [vera-bernhard.github.io/5-6-7-8](https://vera-bernhard.github.io/5-6-7-8/)
   in **Safari**.
2. Tap the **Share** button (the square with an arrow pointing up).
3. Scroll down and tap **Add to Home Screen**. If you don't see it, tap
   **Edit Actions…** and add it.
4. Keep or change the name and tap **Add**.

The 5-6-7-8 icon now appears on your home screen. On iOS 16.4 and later this
also works from Chrome or Edge via their Share menu.

### Install on Android
1. Open [vera-bernhard.github.io/5-6-7-8](https://vera-bernhard.github.io/5-6-7-8/)
   in **Chrome**.
2. Tap the **⋮** menu at the top right.
3. Tap **Add to Home screen** (or **Install app**), then **Install**.

Chrome may also offer to install the app in a banner at the bottom of the
screen. Other browsers such as Samsung Internet have the same option in their
menu.

### Good to know
- Always open 5-6-7-8 from the home-screen icon. On iPhone, the installed app
  has its own storage, separate from Safari: songs imported in a Safari tab
  don't show up in the installed app and vice versa.
- Open the app once while online after installing, so it is ready for offline
  use.
- Removing the app from the home screen (on iPhone) or clearing the browser's
  website data deletes your imported songs and timestamps.

## Run, build and deploy

Requires a [Flutter SDK](https://docs.flutter.dev/get-started/install).

```bash
flutter pub get
flutter run -d chrome          # run locally
flutter test test/audio_analysis_test.dart
flutter build web --release    # build the PWA into build/web
```

Pushing to the `pwa` branch deploys the web app to GitHub Pages
(`.github/workflows/deploy.yml`).

---

## How it is implemented

### Overview

| File | Purpose |
| --- | --- |
| `lib/screens/home.dart` | Library and player screens, playback logic, lead-in/out, random practice, background analysis queue |
| `lib/widgets/waveform_player.dart` | Waveform, BPM band, countdown overlay and player buttons |
| `lib/services/song_storage.dart` | Saving songs, timestamps, random state and analysis results |
| `lib/services/app_settings.dart` | Saving the chosen language |
| `lib/l10n/app_*.arb` | All texts of the app, in English and German |
| `lib/services/audio_decoder*.dart` | Decoding audio for analysis (browser only) |
| `lib/services/audio_analysis.dart` | Waveform, tempo and song-change analysis |
| `lib/models/` | `Timestamp`, `SongAnalysis` and `BpmSection` data classes |

### Texts and languages

The texts are not in the code but in `lib/l10n/app_en.arb` (English, also the
fallback) and `lib/l10n/app_de.arb` (German). Flutter generates
`lib/l10n/app_localizations*.dart` from them on `flutter pub get`, `run`,
`build` and `test`, or with `flutter gen-l10n`. To change a text, edit both
`.arb` files. To add a text, add it to `app_en.arb` first, then translate it in
`app_de.arb`. Another language is one more `app_<code>.arb` file plus its name
in `lib/widgets/language_menu.dart`. The language chosen in the app is saved
with Hive, like the songs; without one, the device's language is used.

### Storage

Songs are stored with [Hive](https://pub.dev/packages/hive_flutter); in the
browser this is IndexedDB. Each song is saved together with its audio bytes,
timestamps, random-practice state and analysis result. That keeps the web app
self-contained, but large libraries use a lot of browser storage.

All saves go through one queue and run one after another. Without that, the
background analysis saving its result could overwrite a timestamp you added at
the same moment.

### Playback, lead-in and lead-out

Playback uses [just_audio](https://pub.dev/packages/just_audio). For a segment
the app seeks to *start − lead-in*, plays, and pauses when the position reaches
*end + lead-out*. If the start lies before 0:00 or the end after the song, a
timer counts the missing time down in silence before starting, or after the
song has finished.

### Waveform and BPM analysis

The analysis runs once per song, in the background after import, so you can
start adding timestamps right away. The result is stored with the song, so it
never runs twice. It is only available in the web app, because it uses the
browser's audio decoder.

**1. Decoding.** The browser's Web Audio API (`OfflineAudioContext` +
`decodeAudioData`) decodes the file and resamples it to 11,025 Hz. The
channels are mixed to mono. This low sample rate keeps memory use small and is
still plenty for loudness and rhythm.

**2. Waveform.** The song is split into 1,000 equal pieces, and the loudness
(RMS) of each piece is stored as a number from 0 to 255. Loudness changes make
the transitions between songs of a mix visible.

**3. Onset envelope: "where are the beats?"** The audio is cut into short
steps of about 11.6 ms (about 86 per second). For each step the app measures
the energy in four frequency bands: below 200 Hz (kick), 200–800 Hz (bass,
vocals), 800–3,000 Hz (snare, claps) and above 3,000 Hz (hi-hats). A beat
shows up as a sudden *increase* in energy, so the envelope is the sum of the
positive changes in loudness (in dB) of each band from one step to the next,
with the slow loudness trend removed. Separate bands make every instrument's
rhythm count, not only the loudest one. The result is a curve with a spike at
every drum hit or note onset. It is stored too, so tempos can be recomputed
later without decoding the audio again.

**4. Tempo from autocorrelation.** Music repeats: if the beat is every 0.47 s,
the onset curve looks similar to itself shifted by 0.47 s. The app compares the
curve with shifted copies of itself (autocorrelation) for every shift between
the beat lengths of 40 and 180 BPM, and picks the shift that matches best.
Three extra rules make the result reliable:
- The match at twice the shift is added, because a real beat also repeats
  every two beats.
- A preference for tempos around 125 BPM avoids "half" or "double" errors,
  e.g. reporting 64 instead of 128.
- Tempos below 80 are doubled. Some songs (half-time feel) mostly repeat every
  two beats, and dancers count those at double speed.

The best shift is then refined to a fraction of a step by checking up to 8
beats in a row, which gives a precision of a fraction of a BPM.

**5. Finding the song changes in a mix.** A single BPM number is not good
enough for this: it can jump within a song (for example between 70, 94 and
141), and two songs can have the same tempo. So the app compares the whole
*rhythm pattern* instead:
- Every 0.5 s it computes the autocorrelation of the surrounding 6 seconds.
  This "rhythm fingerprint" (a tempogram) describes which repetitions are
  strong: beats, half-bars, bars.
- For every point in time it compares the average fingerprint of the 8 seconds
  before with the 8 seconds after. Inside a song they are almost the same; at a
  song change they differ a lot.
- Clear peaks of this difference become song changes. Around a change the
  difference stays high for a few seconds, so the change is placed in the
  middle of that plateau. Silent gaps of at least 0.3 s also count.
- Changes in the first and last 15 seconds are ignored (usually an intro or
  outro), and every section must be at least 10 seconds long.
- Finally each change is moved onto a nearby (±2 s) point where the loudness
  clearly rises, if there is one: the end of a short gap or dip, or the start
  of a louder song. That is where you hear the next song start.

**6. BPM per section.** The tempo of each section is computed from its whole
length with step 4, which is more accurate than short windows.

**7. BPM over the song (chart).** Only when the chart is opened, the tempo is
computed with step 4 for every second, from the 8 seconds around it. Seconds
without a clear beat are left out, and each value is the median of the seconds
around it, so short outliers at song changes disappear.

**Keeping the app responsive.** Flutter web has no background threads for
Dart code, so the analysis runs on the UI thread in small chunks and lets the
UI draw in between, so a routine of a few minutes is analyzed in a moment. If
a file cannot be decoded, that is saved too, so it is not retried on every
start.

**Limits.** The analysis was tuned on synthetic test tracks and one real
aerobics mix, where it places the song changes within about a second. A short
transition of a few seconds between two songs (for example a riser) is not a
section of its own, and a long intro without drums can be detected as an extra
section. When the algorithm changes, `kAnalysisVersion` in
`lib/models/song_analysis.dart` is increased, and all songs are re-analyzed
once in the background.

## Tech stack

- [Flutter](https://flutter.dev) (web/PWA, also builds for Android, iOS and
  desktop; the waveform and BPM analysis are web-only)
- Audio playback: [just_audio](https://pub.dev/packages/just_audio)
- Audio decoding for analysis: Web Audio API via
  [package:web](https://pub.dev/packages/web)
- Local storage: [hive_flutter](https://pub.dev/packages/hive_flutter)
- File picking: [file_picker](https://pub.dev/packages/file_picker)
- Texts in English and German: Flutter's `gen-l10n` with
  [flutter_localizations](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
