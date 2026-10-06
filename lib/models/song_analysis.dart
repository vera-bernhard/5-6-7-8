import 'dart:typed_data';

/// Bump when the analysis algorithm changes, so stored results get recomputed.
const int kAnalysisVersion = 3;

class BpmSection {
  final double start;
  final double end;
  final double bpm;
  final double confidence;

  BpmSection({
    required this.start,
    required this.end,
    required this.bpm,
    this.confidence = 0,
  });

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'bpm': bpm,
        'confidence': confidence,
      };

  factory BpmSection.fromJson(Map<String, dynamic> json) => BpmSection(
        start: (json['start'] as num).toDouble(),
        end: (json['end'] as num).toDouble(),
        bpm: (json['bpm'] as num).toDouble(),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      );
}

class SongAnalysis {
  final int version;
  final double durationSeconds;

  /// Loudness per bucket over the whole song, 0–255.
  final Uint8List waveform;

  /// Frames per second of [onsetEnvelope].
  final double envelopeFps;

  /// Onset strength, 0–255. Kept so the BPM of any range can be computed
  /// later without decoding the audio again.
  final Uint8List onsetEnvelope;

  final List<BpmSection> sections;

  SongAnalysis({
    this.version = kAnalysisVersion,
    required this.durationSeconds,
    required this.waveform,
    required this.envelopeFps,
    required this.onsetEnvelope,
    required this.sections,
  });

  /// A result for audio that could not be decoded or analyzed. The player
  /// keeps the placeholder waveform and shows no sections.
  factory SongAnalysis.failed() => SongAnalysis(
        durationSeconds: 0,
        waveform: Uint8List(0),
        envelopeFps: 0,
        onsetEnvelope: Uint8List(0),
        sections: const <BpmSection>[],
      );

  bool get isCurrent => version == kAnalysisVersion;

  Map<String, dynamic> toJson() => {
        'version': version,
        'durationSeconds': durationSeconds,
        'waveform': waveform,
        'envelopeFps': envelopeFps,
        'onsetEnvelope': onsetEnvelope,
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  factory SongAnalysis.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    return SongAnalysis(
      version: (json['version'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num).toDouble(),
      waveform: _parseBytes(json['waveform']),
      envelopeFps: (json['envelopeFps'] as num).toDouble(),
      onsetEnvelope: _parseBytes(json['onsetEnvelope']),
      sections: rawSections is List
          ? rawSections
              .map((s) => BpmSection.fromJson((s as Map).map(
                    (key, value) => MapEntry(key.toString(), value),
                  )))
              .toList()
          : <BpmSection>[],
    );
  }

  static Uint8List _parseBytes(dynamic raw) {
    if (raw is Uint8List) return raw;
    if (raw is List) return Uint8List.fromList(raw.cast<int>());
    return Uint8List(0);
  }
}
