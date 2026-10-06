import 'dart:typed_data';

class DecodedAudio {
  final Float32List samples;
  final int sampleRate;

  DecodedAudio(this.samples, this.sampleRate);
}

/// Audio decoding for analysis is only available on the web.
Future<DecodedAudio?> decodeForAnalysis(Uint8List bytes) async => null;
