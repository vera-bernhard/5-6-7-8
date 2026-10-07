// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get library => 'Library';

  @override
  String get player => 'Player';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get imprint => 'About';

  @override
  String authorLine(String name) {
    return 'Developer: $name';
  }

  @override
  String get madeFor =>
      'Made with passion for team aerobics at TV Lenzburg. 5, 6, 7, 8 and go!';

  @override
  String get betaNotice => 'Beta version: there may still be bugs and changes.';

  @override
  String get openSource => 'Open source';

  @override
  String get builtWith => 'Built with';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get noSongsYet => 'No songs yet. Upload your first song below.';

  @override
  String get uploadSong => 'Upload Song';

  @override
  String get preparingUpload => 'Preparing Upload...';

  @override
  String timestampCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count timestamps',
      one: '1 timestamp',
    );
    return '$_temp0';
  }

  @override
  String get audioPickerTimedOut => 'Audio picker timed out. Please try again.';

  @override
  String get audioPickerFailed => 'Audio picker failed. Please try again.';

  @override
  String selectAudioFile(String extensions) {
    return 'Please select an audio file ($extensions).';
  }

  @override
  String get couldNotReadAudioFile => 'Could not read the selected audio file.';

  @override
  String get couldNotProcessFile => 'Could not process the selected file.';

  @override
  String get nameSongTitle => 'Name this song';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get renameSongTitle => 'Rename song';

  @override
  String get songNameLabel => 'Song name';

  @override
  String get deleteSongTitle => 'Delete song?';

  @override
  String deleteSongMessage(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count timestamps',
      one: '1 timestamp',
    );
    return 'Do you really want to delete \"$name\" with $_temp0? This cannot be undone.';
  }

  @override
  String get noSongSelected =>
      'No song selected. Open Library and choose a song.';

  @override
  String couldNotLoadSong(String name) {
    return 'Could not load \"$name\".';
  }

  @override
  String get audioNotLoaded => 'Song selected, but audio is not loaded yet.';

  @override
  String get analyzing => 'Analyzing';

  @override
  String get leadIn => 'Lead-in';

  @override
  String get leadOut => 'Lead-out';

  @override
  String get startingIn => 'Starting in';

  @override
  String get endingIn => 'Ending in';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get saveTimestamp => 'Save Timestamp';

  @override
  String speedTooltip(String speed) {
    return 'Speed $speed';
  }

  @override
  String shuffleTooltip(int remaining, int total) {
    return 'Shuffle ($remaining/$total left)';
  }

  @override
  String get noTimestampsYet => 'No timestamps yet.';

  @override
  String timestampDefaultName(int number) {
    return 'Timestamp $number';
  }

  @override
  String get nameTimestampTitle => 'Name This Timestamp';

  @override
  String get timestampNameLabel => 'Timestamp name';

  @override
  String get timestampNameHint => 'e.g. Chorus start';

  @override
  String get timeLabel => 'Time';

  @override
  String get timeHint => 'e.g. 1:23 or 83.5';

  @override
  String get invalidTime =>
      'Invalid time. Use mm:ss or seconds, e.g. 1:23 or 83.5.';

  @override
  String get deleteTimestampTitle => 'Delete timestamp?';

  @override
  String get deleteTimestampUnnamed =>
      'This timestamp will be removed permanently.';

  @override
  String deleteTimestampNamed(String label) {
    return '\"$label\" will be removed permanently.';
  }

  @override
  String get shuffleTitle => 'Shuffle';

  @override
  String get shuffleNoSegments => 'Please select segments for shuffling first.';

  @override
  String get shuffleAllPlayed =>
      'All selected shuffle segments were already played. Long-press shuffle to reset.';

  @override
  String get playbackSpeedTitle => 'Playback Speed';

  @override
  String get speedLabel => 'Speed';

  @override
  String get bpmOverSong => 'BPM over the song';

  @override
  String get showBpmOverSong => 'Show BPM over the song';

  @override
  String get noClearBeat => 'No clear beat found.';

  @override
  String get bpmChartNote =>
      'Measured every second over 8 s. Gaps: no clear beat.';
}
