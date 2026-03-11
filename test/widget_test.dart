import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audio_timestamp_trainer_flutter/main.dart';

void main() {
  testWidgets('renders trainer home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('Audio Timestamp Trainer'), findsOneWidget);
    expect(find.textContaining('No audio selected'), findsOneWidget);
  });

  testWidgets('shows action buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.byIcon(Icons.folder_open), findsOneWidget);
    expect(find.byIcon(Icons.add_location), findsOneWidget);
  });
}
