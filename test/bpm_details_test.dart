import 'dart:typed_data';

import 'package:five_six_seven_eight/l10n/app_localizations.dart';
import 'package:five_six_seven_eight/models/song_analysis.dart';
import 'package:five_six_seven_eight/widgets/bpm_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BPM details show the chart and every section', (tester) async {
    // An onset every 0.5 s: 120 BPM.
    const fps = 86.0;
    final envelope = Uint8List(60 * 86);
    for (var i = 0; i < envelope.length; i += 43) {
      envelope[i] = 255;
    }
    final analysis = SongAnalysis(
      durationSeconds: 60,
      waveform: Uint8List(0),
      envelopeFps: fps,
      onsetEnvelope: envelope,
      sections: [
        BpmSection(start: 0, end: 30, bpm: 120),
        BpmSection(start: 30, end: 60, bpm: 120.4),
      ],
    );
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showBpmDetails(context, analysis),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('BPM over the song'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('0:00 – 0:30'), findsOneWidget);
    expect(find.text('0:30 – 1:00'), findsOneWidget);
    expect(find.text('120 BPM'), findsNWidgets(2));

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('BPM over the song'), findsNothing);
  });
}
