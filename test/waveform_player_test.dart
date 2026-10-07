import 'package:five_six_seven_eight/l10n/app_localizations.dart';
import 'package:five_six_seven_eight/models/song_analysis.dart';
import 'package:five_six_seven_eight/widgets/waveform_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget player(
  List<BpmSection> sections, {
  Duration position = Duration.zero,
  VoidCallback? onShowBpmDetails,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 360,
        child: WaveformPlayer(
          position: position,
          duration: Duration(seconds: sections.last.end.round()),
          isPlaying: false,
          enabled: true,
          onPlayPause: () {},
          onShufflePlay: () {},
          onShuffleReset: () {},
          onToggleSpeed: () {},
          speedLabel: '1.0x',
          shufflePlayEnabled: false,
          shuffleSectionsTotal: 0,
          shuffleSectionsRemaining: 0,
          onSeek: (_) {},
          sections: sections,
          onShowBpmDetails: onShowBpmDetails,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('BPM band shows the tempo of a narrow section', (tester) async {
    await tester.pumpWidget(player([
      BpmSection(start: 0, end: 60, bpm: 120),
      BpmSection(start: 60, end: 70, bpm: 140),
      BpmSection(start: 70, end: 130, bpm: 125),
    ]));
    expect(find.text('120 BPM'), findsOneWidget);
    expect(find.text('140'), findsOneWidget);
    expect(find.text('125'), findsOneWidget);
  });

  testWidgets('BPM band shows the unit only for the playing section',
      (tester) async {
    await tester.pumpWidget(player(
      [
        BpmSection(start: 0, end: 60, bpm: 120),
        BpmSection(start: 60, end: 70, bpm: 140),
        BpmSection(start: 70, end: 130, bpm: 125),
      ],
      position: const Duration(seconds: 65),
    ));
    expect(find.text('140 BPM'), findsOneWidget);
    expect(find.textContaining('BPM'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('125'), findsOneWidget);
  });

  testWidgets('BPM band always shows the tempo of the playing section',
      (tester) async {
    // Far too narrow for all three labels.
    await tester.pumpWidget(player(
      [
        BpmSection(start: 0, end: 60, bpm: 120),
        BpmSection(start: 60, end: 62, bpm: 141),
        BpmSection(start: 62, end: 64, bpm: 142),
        BpmSection(start: 64, end: 66, bpm: 143),
        BpmSection(start: 66, end: 130, bpm: 125),
      ],
      position: const Duration(seconds: 63),
    ));
    expect(find.text('142 BPM'), findsOneWidget);
  });

  testWidgets('tapping a BPM number shows the details', (tester) async {
    var shown = 0;
    await tester.pumpWidget(player(
      [
        BpmSection(start: 0, end: 60, bpm: 120),
        BpmSection(start: 60, end: 130, bpm: 125),
      ],
      onShowBpmDetails: () => shown++,
    ));
    await tester.tap(find.text('125'));
    expect(shown, 1);
  });
}
