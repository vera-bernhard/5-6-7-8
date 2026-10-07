import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de')
  ];

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language menu entry that follows the language of the device.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get languageSystem;

  /// Button that shows who made the app (Impressum).
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get imprint;

  /// No description provided for @authorLine.
  ///
  /// In en, this message translates to:
  /// **'Developer: {name}'**
  String authorLine(String name);

  /// No description provided for @madeFor.
  ///
  /// In en, this message translates to:
  /// **'Made with passion for team aerobics at TV Lenzburg. 5, 6, 7, 8 and go!'**
  String get madeFor;

  /// No description provided for @betaNotice.
  ///
  /// In en, this message translates to:
  /// **'Beta version: there may still be bugs and changes.'**
  String get betaNotice;

  /// No description provided for @openSource.
  ///
  /// In en, this message translates to:
  /// **'Open source'**
  String get openSource;

  /// Followed by the Flutter logo and the word Flutter.
  ///
  /// In en, this message translates to:
  /// **'Built with'**
  String get builtWith;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noSongsYet.
  ///
  /// In en, this message translates to:
  /// **'No songs yet. Upload your first song below.'**
  String get noSongsYet;

  /// No description provided for @uploadSong.
  ///
  /// In en, this message translates to:
  /// **'Upload Song'**
  String get uploadSong;

  /// No description provided for @preparingUpload.
  ///
  /// In en, this message translates to:
  /// **'Preparing Upload...'**
  String get preparingUpload;

  /// No description provided for @timestampCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 timestamp} other{{count} timestamps}}'**
  String timestampCount(int count);

  /// No description provided for @audioPickerTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Audio picker timed out. Please try again.'**
  String get audioPickerTimedOut;

  /// No description provided for @audioPickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Audio picker failed. Please try again.'**
  String get audioPickerFailed;

  /// No description provided for @selectAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Please select an audio file ({extensions}).'**
  String selectAudioFile(String extensions);

  /// No description provided for @couldNotReadAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected audio file.'**
  String get couldNotReadAudioFile;

  /// No description provided for @couldNotProcessFile.
  ///
  /// In en, this message translates to:
  /// **'Could not process the selected file.'**
  String get couldNotProcessFile;

  /// No description provided for @nameSongTitle.
  ///
  /// In en, this message translates to:
  /// **'Name this song'**
  String get nameSongTitle;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @renameSongTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename song'**
  String get renameSongTitle;

  /// No description provided for @songNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Song name'**
  String get songNameLabel;

  /// No description provided for @deleteSongTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete song?'**
  String get deleteSongTitle;

  /// No description provided for @deleteSongMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete \"{name}\" with {count, plural, =1{1 timestamp} other{{count} timestamps}}? This cannot be undone.'**
  String deleteSongMessage(String name, int count);

  /// No description provided for @noSongSelected.
  ///
  /// In en, this message translates to:
  /// **'No song selected. Open Library and choose a song.'**
  String get noSongSelected;

  /// No description provided for @couldNotLoadSong.
  ///
  /// In en, this message translates to:
  /// **'Could not load \"{name}\".'**
  String couldNotLoadSong(String name);

  /// No description provided for @audioNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Song selected, but audio is not loaded yet.'**
  String get audioNotLoaded;

  /// Shown next to a spinner while the waveform and BPM are computed.
  ///
  /// In en, this message translates to:
  /// **'Analyzing'**
  String get analyzing;

  /// Seconds that replay starts before a timestamp.
  ///
  /// In en, this message translates to:
  /// **'Lead-in'**
  String get leadIn;

  /// Seconds that a segment keeps playing past its end.
  ///
  /// In en, this message translates to:
  /// **'Lead-out'**
  String get leadOut;

  /// Countdown before playback starts, followed by the seconds left.
  ///
  /// In en, this message translates to:
  /// **'Starting in'**
  String get startingIn;

  /// Countdown before playback ends, followed by the seconds left.
  ///
  /// In en, this message translates to:
  /// **'Ending in'**
  String get endingIn;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @saveTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Save Timestamp'**
  String get saveTimestamp;

  /// No description provided for @speedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Speed {speed}'**
  String speedTooltip(String speed);

  /// No description provided for @shuffleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Shuffle ({remaining}/{total} left)'**
  String shuffleTooltip(int remaining, int total);

  /// No description provided for @noTimestampsYet.
  ///
  /// In en, this message translates to:
  /// **'No timestamps yet.'**
  String get noTimestampsYet;

  /// Name of a timestamp the user didn't name.
  ///
  /// In en, this message translates to:
  /// **'Timestamp {number}'**
  String timestampDefaultName(int number);

  /// No description provided for @nameTimestampTitle.
  ///
  /// In en, this message translates to:
  /// **'Name This Timestamp'**
  String get nameTimestampTitle;

  /// No description provided for @timestampNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Timestamp name'**
  String get timestampNameLabel;

  /// No description provided for @timestampNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chorus start'**
  String get timestampNameHint;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @timeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1:23 or 83.5'**
  String get timeHint;

  /// No description provided for @invalidTime.
  ///
  /// In en, this message translates to:
  /// **'Invalid time. Use mm:ss or seconds, e.g. 1:23 or 83.5.'**
  String get invalidTime;

  /// No description provided for @deleteTimestampTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete timestamp?'**
  String get deleteTimestampTitle;

  /// No description provided for @deleteTimestampUnnamed.
  ///
  /// In en, this message translates to:
  /// **'This timestamp will be removed permanently.'**
  String get deleteTimestampUnnamed;

  /// No description provided for @deleteTimestampNamed.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" will be removed permanently.'**
  String deleteTimestampNamed(String label);

  /// No description provided for @shuffleTitle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffleTitle;

  /// No description provided for @shuffleNoSegments.
  ///
  /// In en, this message translates to:
  /// **'Please select segments for shuffling first.'**
  String get shuffleNoSegments;

  /// No description provided for @shuffleAllPlayed.
  ///
  /// In en, this message translates to:
  /// **'All selected shuffle segments were already played. Long-press shuffle to reset.'**
  String get shuffleAllPlayed;

  /// No description provided for @playbackSpeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeedTitle;

  /// No description provided for @speedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speedLabel;

  /// No description provided for @bpmOverSong.
  ///
  /// In en, this message translates to:
  /// **'BPM over the song'**
  String get bpmOverSong;

  /// No description provided for @showBpmOverSong.
  ///
  /// In en, this message translates to:
  /// **'Show BPM over the song'**
  String get showBpmOverSong;

  /// No description provided for @noClearBeat.
  ///
  /// In en, this message translates to:
  /// **'No clear beat found.'**
  String get noClearBeat;

  /// No description provided for @bpmChartNote.
  ///
  /// In en, this message translates to:
  /// **'Measured every second over 8 s. Gaps: no clear beat.'**
  String get bpmChartNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
