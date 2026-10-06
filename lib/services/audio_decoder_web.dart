import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

class DecodedAudio {
  final Float32List samples;
  final int sampleRate;

  DecodedAudio(this.samples, this.sampleRate);
}

/// Decodes [bytes] with the browser's Web Audio decoder into mono samples at a
/// low sample rate, which is enough for the waveform and tempo analysis.
Future<DecodedAudio?> decodeForAnalysis(Uint8List bytes) async {
  web.OfflineAudioContext context;
  try {
    context = web.OfflineAudioContext(1.toJS, 1, 11025);
  } catch (_) {
    // Some browsers don't support low sample rates.
    context = web.OfflineAudioContext(1.toJS, 1, 44100);
  }

  // decodeAudioData detaches the buffer it receives, so pass a copy.
  final copy = Uint8List.fromList(bytes);
  final buffer = await context.decodeAudioData(copy.buffer.toJS).toDart;

  final channels = buffer.numberOfChannels;
  final length = buffer.length;
  final mono = Float32List(length);
  for (var c = 0; c < channels; c++) {
    final data = buffer.getChannelData(c).toDart;
    for (var i = 0; i < length; i++) {
      mono[i] += data[i];
    }
  }
  if (channels > 1) {
    final scale = 1 / channels;
    for (var i = 0; i < length; i++) {
      mono[i] *= scale;
    }
  }
  return DecodedAudio(mono, buffer.sampleRate.round());
}
