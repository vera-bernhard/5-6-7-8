import 'dart:math' as math;
import 'dart:typed_data';

import 'package:five_six_seven_eight/models/song_analysis.dart';
import 'package:five_six_seven_eight/services/audio_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

const int sampleRate = 11025;

/// A sustained pad with a kick-like click on every beat.
List<double> beatTrack(double bpm, double seconds, {double padHz = 220}) {
  final length = (seconds * sampleRate).round();
  final out = List<double>.filled(length, 0);
  final random = math.Random(bpm.round());
  for (var i = 0; i < length; i++) {
    final t = i / sampleRate;
    out[i] = 0.08 * math.sin(2 * math.pi * padHz * t) +
        0.01 * (random.nextDouble() * 2 - 1);
  }
  final beat = 60 / bpm;
  for (var b = 0.0; b < seconds; b += beat) {
    final start = (b * sampleRate).round();
    for (var j = 0; j < 0.06 * sampleRate && start + j < length; j++) {
      final t = j / sampleRate;
      final decay = math.exp(-t * 60);
      out[start + j] += 0.8 *
          decay *
          (math.sin(2 * math.pi * 60 * t) +
              0.5 * (random.nextDouble() * 2 - 1));
    }
  }
  return out;
}

Float32List concat(List<List<double>> parts) =>
    Float32List.fromList(parts.expand((p) => p).toList());

void main() {
  test('estimates the tempo of a steady beat', () async {
    final analysis =
        await analyzeAudio(concat([beatTrack(128, 30)]), sampleRate);
    final estimate = estimateBpm(analysis.onsetEnvelope, analysis.envelopeFps,
        0, analysis.durationSeconds);
    expect(estimate, isNotNull);
    expect(estimate!.bpm, closeTo(128, 1.5));
  });

  test('splits a mix into sections at the song change', () async {
    final silence = List<double>.filled(sampleRate ~/ 2, 0);
    final analysis = await analyzeAudio(
      concat([beatTrack(120, 30), silence, beatTrack(140, 30, padHz: 330)]),
      sampleRate,
    );
    expect(analysis.sections, hasLength(2));
    expect(analysis.sections[0].bpm, closeTo(120, 1.5));
    expect(analysis.sections[1].bpm, closeTo(140, 1.5));
    expect(analysis.sections[1].start, closeTo(30.25, 2));
  });

  test('finds a tempo change without a silent gap', () async {
    final analysis = await analyzeAudio(
      concat([beatTrack(125, 40), beatTrack(150, 40)]),
      sampleRate,
    );
    expect(analysis.sections, hasLength(2));
    expect(analysis.sections[0].bpm, closeTo(125, 1.5));
    expect(analysis.sections[1].bpm, closeTo(150, 1.5));
    expect(analysis.sections[1].start, closeTo(40, 3));
  });

  test('places a late song change where the next song starts', () async {
    // A quiet breath between the songs, too loud to count as silence.
    final breath = List<double>.generate((1.5 * sampleRate).round(),
        (i) => 0.02 * math.sin(2 * math.pi * 220 * i / sampleRate));
    final analysis = await analyzeAudio(
      concat([beatTrack(125, 150), breath, beatTrack(140, 40, padHz: 330)]),
      sampleRate,
    );
    expect(analysis.sections, hasLength(2));
    expect(analysis.sections[1].start, closeTo(151.5, 0.75));
  });

  test('tempo curve follows a tempo change', () async {
    final analysis = await analyzeAudio(
      concat([beatTrack(125, 40), beatTrack(150, 40)]),
      sampleRate,
    );
    final curve = await tempoCurve(analysis);
    for (final point in curve) {
      if (point.seconds > 5 && point.seconds < 35) {
        expect(point.bpm, closeTo(125, 1.5));
      }
      if (point.seconds > 45 && point.seconds < 75) {
        expect(point.bpm, closeTo(150, 1.5));
      }
    }
    expect(curve.where((p) => p.seconds > 5 && p.seconds < 35), hasLength(29));
    expect(curve.where((p) => p.seconds > 45 && p.seconds < 75), hasLength(29));
  });

  test('waveform shows the gap between songs', () async {
    final silence = List<double>.filled(sampleRate * 2, 0);
    final analysis = await analyzeAudio(
      concat([beatTrack(120, 20), silence, beatTrack(120, 20)]),
      sampleRate,
    );
    final w = analysis.waveform;
    expect(w, hasLength(1000));
    final gapBucket = (21 / 42 * w.length).round();
    expect(w[gapBucket], lessThan(10));
    final songLevel = w.sublist(50, 450).reduce((a, b) => a + b) / 400;
    expect(songLevel, greaterThan(50));
  });

  test('analysis survives a JSON round trip', () async {
    final analysis =
        await analyzeAudio(concat([beatTrack(128, 20)]), sampleRate);
    final restored = SongAnalysis.fromJson(analysis.toJson());
    expect(restored.version, kAnalysisVersion);
    expect(restored.waveform, analysis.waveform);
    expect(restored.onsetEnvelope, analysis.onsetEnvelope);
    expect(restored.sections.single.bpm, analysis.sections.single.bpm);
  });
}
