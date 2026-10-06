import 'dart:math' as math;
import 'dart:typed_data';

import '../models/song_analysis.dart';

const int _waveformBuckets = 1000;
const double _hopSeconds = 0.0116;
// Tempos are reported between 80 and 180 BPM. Slower periods (down to 40) are
// still searched, because some songs (half-time feel) mostly repeat every
// two beats, and are then reported at double speed.
const double _minBpm = 80;
const double _searchMinBpm = 40;
const double _maxBpm = 180;
const double _preferredBpm = 125;
const double _minSectionSeconds = 10;
const double _edgeSeconds = 15;
const double _tempogramWindowSeconds = 6;
const double _tempogramStepSeconds = 0.5;
const double _noveltySpanSeconds = 8;
const double _noveltyThreshold = 0.4;
const double _peakSuppressSeconds = 3;
const double _refineSeconds = 2;
const double _snapSeconds = 4;
const double _minSnapDb = 3;
const double _minSnappedSeconds = 6;

/// Lets the UI render between chunks of work. Flutter web has no isolates, so
/// the analysis runs on the UI thread in small pieces.
Future<void> _yield() => Future<void>.delayed(Duration.zero);

class BpmEstimate {
  final double bpm;
  final double confidence;

  BpmEstimate(this.bpm, this.confidence);
}

/// Computes the waveform, onset envelope and BPM sections of mono [samples].
Future<SongAnalysis> analyzeAudio(Float32List samples, int sampleRate) async {
  final duration = samples.length / sampleRate;
  final waveform = await _computeWaveform(samples);

  final energies = await _computeHopEnergies(samples, sampleRate);
  final fps = sampleRate / energies.hop;
  final envelope = _onsetEnvelope(energies, fps);
  await _yield();

  final boundaries = await _findBoundaries(energies, envelope, fps, duration);
  final sections = <BpmSection>[];
  final edges = <double>[0, ...boundaries, duration];
  for (var i = 0; i < edges.length - 1; i++) {
    final estimate = estimateBpm(envelope, fps, edges[i], edges[i + 1]);
    sections.add(BpmSection(
      start: edges[i],
      end: edges[i + 1],
      bpm: estimate?.bpm ?? 0,
      confidence: estimate?.confidence ?? 0,
    ));
  }

  return SongAnalysis(
    durationSeconds: duration,
    waveform: waveform,
    envelopeFps: fps,
    onsetEnvelope: envelope,
    sections: sections,
  );
}

/// Estimates the tempo between [startSec] and [endSec] from an onset
/// envelope. Returns null if the range is too short.
BpmEstimate? estimateBpm(
    Uint8List envelope, double fps, double startSec, double endSec) {
  final start = math.max(0, (startSec * fps).floor());
  final end = math.min(envelope.length, (endSec * fps).ceil());
  final n = end - start;
  final maxLag = (60 * fps / _searchMinBpm).ceil();
  final minLag = math.max(1, (60 * fps / _maxBpm).floor());
  if (n < 4 * fps || n <= 2 * maxLag + 1) return null;

  var mean = 0.0;
  for (var i = start; i < end; i++) {
    mean += envelope[i];
  }
  mean /= n;
  final x = Float64List(n);
  for (var i = 0; i < n; i++) {
    x[i] = envelope[start + i] - mean;
  }

  final acfCache = <int, double>{};
  double acf(int lag) {
    if (lag >= n) return 0;
    return acfCache.putIfAbsent(lag, () {
      var sum = 0.0;
      for (var i = 0; i + lag < n; i++) {
        sum += x[i] * x[i + lag];
      }
      return sum / (n - lag);
    });
  }

  double acfAt(double lag) {
    final lo = lag.floor();
    final t = lag - lo;
    return acf(lo) * (1 - t) + acf(lo + 1) * t;
  }

  final energy = acf(0);
  if (energy <= 0) return null;

  double fold(double bpm) => bpm < _minBpm ? bpm * 2 : bpm;

  // Prior against tempo errors, in octaves around 125 BPM.
  double prior(double bpm) {
    final octaves = math.log(fold(bpm) / _preferredBpm) / math.ln2;
    return math.exp(-0.5 * math.pow(octaves / 0.5, 2));
  }

  double score(double lag) {
    final raw = acfAt(lag) + 0.5 * acfAt(2 * lag);
    return math.max(0.0, raw) * prior(60 * fps / lag);
  }

  var bestLag = minLag.toDouble();
  var bestScore = -1.0;
  for (var lag = minLag; lag <= maxLag; lag++) {
    final s = score(lag.toDouble());
    if (s > bestScore) {
      bestScore = s;
      bestLag = lag.toDouble();
    }
  }
  if (bestScore <= 0) return null;

  // Refine with several beat periods, which gives sub-frame precision.
  final periods = math.max(1, math.min(8, (n ~/ 2) ~/ bestLag));
  var refinedLag = bestLag;
  var refinedScore = double.negativeInfinity;
  for (var lag = bestLag - 1; lag <= bestLag + 1; lag += 0.01) {
    var s = 0.0;
    for (var k = 1; k <= periods; k++) {
      s += acfAt(lag * k);
    }
    if (s > refinedScore) {
      refinedScore = s;
      refinedLag = lag;
    }
  }

  final confidence = (acfAt(refinedLag) / energy).clamp(0.0, 1.0);
  return BpmEstimate(fold(60 * fps / refinedLag), confidence);
}

Future<Uint8List> _computeWaveform(Float32List samples) async {
  final buckets = Float64List(_waveformBuckets);
  final perBucket = samples.length / _waveformBuckets;
  for (var b = 0; b < _waveformBuckets; b++) {
    final from = (b * perBucket).floor();
    final to = math.min(samples.length, ((b + 1) * perBucket).floor());
    var sum = 0.0;
    for (var i = from; i < to; i++) {
      sum += samples[i] * samples[i];
    }
    buckets[b] = to > from ? math.sqrt(sum / (to - from)) : 0;
    if (b % 100 == 99) await _yield();
  }
  final reference = _percentile(buckets, 0.99);
  final result = Uint8List(_waveformBuckets);
  if (reference <= 0) return result;
  for (var b = 0; b < _waveformBuckets; b++) {
    result[b] = (buckets[b] / reference * 255).round().clamp(0, 255);
  }
  return result;
}

class _HopEnergies {
  final int hop;
  final Float64List full;
  final Float64List low;

  _HopEnergies(this.hop, this.full, this.low);
}

/// Mean energy per hop, of the full signal and of a ~200 Hz lowpass (kick).
Future<_HopEnergies> _computeHopEnergies(
    Float32List samples, int sampleRate) async {
  final hop = math.max(1, (sampleRate * _hopSeconds).round());
  final count = samples.length ~/ hop;
  final full = Float64List(count);
  final low = Float64List(count);
  final alpha = 1 - math.exp(-2 * math.pi * 200 / sampleRate);
  var lp = 0.0;
  for (var h = 0; h < count; h++) {
    var sumFull = 0.0;
    var sumLow = 0.0;
    final from = h * hop;
    for (var i = from; i < from + hop; i++) {
      final s = samples[i];
      lp += alpha * (s - lp);
      sumFull += s * s;
      sumLow += lp * lp;
    }
    full[h] = sumFull / hop;
    low[h] = sumLow / hop;
    if (h % 20000 == 19999) await _yield();
  }
  return _HopEnergies(hop, full, low);
}

Float64List _toDb(Float64List energies) {
  var peak = 0.0;
  for (final e in energies) {
    if (e > peak) peak = e;
  }
  final floor = math.max(peak * 1e-6, 1e-12);
  final db = Float64List(energies.length);
  for (var i = 0; i < energies.length; i++) {
    db[i] = 10 * math.log(math.max(energies[i], floor)) / math.ln10;
  }
  return db;
}

Uint8List _onsetEnvelope(_HopEnergies energies, double fps) {
  final fullDb = _toDb(energies.full);
  final lowDb = _toDb(energies.low);
  final count = fullDb.length;
  final raw = Float64List(count);
  for (var i = 1; i < count; i++) {
    raw[i] = math.max(0.0, fullDb[i] - fullDb[i - 1]) +
        math.max(0.0, lowDb[i] - lowDb[i - 1]);
  }

  // Remove the slowly changing part (moving average over ~0.5 s).
  final half = math.max(1, (0.25 * fps).round());
  final prefix = Float64List(count + 1);
  for (var i = 0; i < count; i++) {
    prefix[i + 1] = prefix[i] + raw[i];
  }
  final detrended = Float64List(count);
  for (var i = 0; i < count; i++) {
    final from = math.max(0, i - half);
    final to = math.min(count, i + half + 1);
    final avg = (prefix[to] - prefix[from]) / (to - from);
    detrended[i] = math.max(0.0, raw[i] - avg);
  }

  final reference = _percentile(detrended, 0.99);
  final envelope = Uint8List(count);
  if (reference <= 0) return envelope;
  for (var i = 0; i < count; i++) {
    envelope[i] = (detrended[i] / reference * 255).round().clamp(0, 255);
  }
  return envelope;
}

/// Finds the times where one song in a mix likely changes to the next.
Future<List<double>> _findBoundaries(_HopEnergies energies, Uint8List envelope,
    double fps, double duration) async {
  final silences = _silenceGaps(energies, fps);
  final candidates = <double>[
    ...silences,
    ...await _rhythmChanges(envelope, fps),
  ];

  // Candidates are in priority order; keep each one only if it leaves every
  // section at least the minimum length. Near the start and end, changes are
  // usually an intro or outro rather than a new song.
  final accepted = <double>[];
  for (final t in candidates) {
    if (t < _edgeSeconds || duration - t < _edgeSeconds) continue;
    if (accepted.every((a) => (a - t).abs() >= _minSectionSeconds)) {
      accepted.add(t);
    }
  }

  // Rhythm changes are only accurate to a few seconds; move each one onto a
  // nearby loudness change if that doesn't make a section too short.
  final loudness = _loudnessFrames(energies, fps);
  for (var i = 0; i < accepted.length; i++) {
    if (silences.contains(accepted[i])) continue;
    final snapped = _snapToLoudnessChange(accepted[i], loudness);
    final others = [0.0, duration, ...accepted]..removeAt(i + 2);
    if (others.every((o) => (o - snapped).abs() >= _minSnappedSeconds)) {
      accepted[i] = snapped;
    }
  }
  accepted.sort();
  return accepted;
}

/// Centres of quiet gaps of at least 0.3 s, longest first.
List<double> _silenceGaps(_HopEnergies energies, double fps) {
  final db = _toDb(energies.full);
  final loud = _percentile(db, 0.95);
  final threshold = loud - 35;
  final minFrames = (0.3 * fps).ceil();

  final gaps = <MapEntry<double, int>>[];
  var runStart = -1;
  for (var i = 0; i <= db.length; i++) {
    final quiet = i < db.length && db[i] < threshold;
    if (quiet && runStart < 0) runStart = i;
    if (!quiet && runStart >= 0) {
      final length = i - runStart;
      if (length >= minFrames) {
        gaps.add(MapEntry((runStart + i) / 2 / fps, length));
      }
      runStart = -1;
    }
  }
  gaps.sort((a, b) => b.value.compareTo(a.value));
  return gaps.map((g) => g.key).toList();
}

const double _loudnessFrameSeconds = 0.25;

/// Loudness in dB per 0.25 s.
Float64List _loudnessFrames(_HopEnergies energies, double fps) {
  final perFrame = math.max(1, (_loudnessFrameSeconds * fps).round());
  final count = energies.full.length ~/ perFrame;
  final frames = Float64List(count);
  for (var f = 0; f < count; f++) {
    var sum = 0.0;
    for (var i = f * perFrame; i < (f + 1) * perFrame; i++) {
      sum += energies.full[i];
    }
    frames[f] = 10 * math.log(sum / perFrame + 1e-12) / math.ln10;
  }
  return frames;
}

/// Song changes in a mix often sit on a short dip or a jump in loudness.
/// Moves [t] to the clearest such point nearby, if there is one.
double _snapToLoudnessChange(double t, Float64List loudness) {
  double meanDb(int from, int to) {
    from = math.max(0, from);
    to = math.min(loudness.length, to);
    if (to <= from) return 0;
    var sum = 0.0;
    for (var i = from; i < to; i++) {
      sum += loudness[i];
    }
    return sum / (to - from);
  }

  final side = (2 / _loudnessFrameSeconds).round();
  final center = (t / _loudnessFrameSeconds).round();
  final reach = (_snapSeconds / _loudnessFrameSeconds).round();
  var bestFrame = -1;
  var bestScore = _minSnapDb;
  for (var f = center - reach; f <= center + reach; f++) {
    if (f - side < 0 || f + side > loudness.length) continue;
    final jump = (meanDb(f, f + side) - meanDb(f - side, f)).abs();
    final dip = meanDb(f - side, f + side) - meanDb(f - 1, f + 1);
    final score = math.max(jump, dip);
    if (score > bestScore) {
      bestScore = score;
      bestFrame = f;
    }
  }
  return bestFrame < 0 ? t : bestFrame * _loudnessFrameSeconds;
}

/// Rhythm "fingerprints": the normalized autocorrelation of the onset
/// envelope in short windows. Two songs differ here even when a single BPM
/// number is ambiguous (e.g. 70 vs 140 vs 94).
Future<List<Float64List>> _tempogram(Uint8List envelope, double fps) async {
  final minLag = math.max(1, (60 * fps / 240).floor());
  final maxLag = (60 * fps / 50).ceil();
  final half = (_tempogramWindowSeconds / 2 * fps).round();
  final columns = <Float64List>[];
  for (var k = 0;; k++) {
    final center = (_tempogramWindowSeconds / 2 + k * _tempogramStepSeconds) *
        fps;
    final from = (center - half).round();
    final to = from + 2 * half;
    if (to > envelope.length) break;
    var mean = 0.0;
    for (var i = from; i < to; i++) {
      mean += envelope[i];
    }
    mean /= to - from;
    final column = Float64List(maxLag - minLag + 1);
    var norm = 0.0;
    for (var lag = minLag; lag <= maxLag; lag++) {
      var sum = 0.0;
      for (var i = from; i + lag < to; i++) {
        sum += (envelope[i] - mean) * (envelope[i + lag] - mean);
      }
      final value = math.max(0.0, sum / (to - from - lag));
      column[lag - minLag] = value;
      norm += value * value;
    }
    norm = math.sqrt(norm);
    if (norm > 0) {
      for (var i = 0; i < column.length; i++) {
        column[i] /= norm;
      }
    }
    columns.add(column);
    if (k % 40 == 39) await _yield();
  }
  return columns;
}

/// Cosine distance between the average rhythm before and after each column,
/// looking [span] columns to each side. Columns whose window overlaps the
/// point itself are skipped.
Float64List _rhythmNovelty(List<Float64List> columns, int span) {
  final novelty = Float64List(columns.length);
  if (columns.isEmpty) return novelty;
  final skip =
      (_tempogramWindowSeconds / 2 / _tempogramStepSeconds).ceil();
  final size = columns.first.length;
  for (var k = span; k + span <= columns.length; k++) {
    final before = Float64List(size);
    final after = Float64List(size);
    for (var j = k - span; j <= k - skip; j++) {
      for (var i = 0; i < size; i++) {
        before[i] += columns[j][i];
      }
    }
    for (var j = k + skip; j < k + span; j++) {
      for (var i = 0; i < size; i++) {
        after[i] += columns[j][i];
      }
    }
    var dot = 0.0;
    var normBefore = 0.0;
    var normAfter = 0.0;
    for (var i = 0; i < size; i++) {
      dot += before[i] * after[i];
      normBefore += before[i] * before[i];
      normAfter += after[i] * after[i];
    }
    final denominator = math.sqrt(normBefore * normAfter);
    novelty[k] = denominator > 0 ? 1 - dot / denominator : 0;
  }
  return novelty;
}

/// Song changes found as peaks in the rhythm novelty, strongest first, each
/// placed precisely with a shorter look-around.
Future<List<double>> _rhythmChanges(Uint8List envelope, double fps) async {
  final columns = await _tempogram(envelope, fps);
  await _yield();
  final coarse = _rhythmNovelty(
      columns, (_noveltySpanSeconds / _tempogramStepSeconds).round());
  final fine = _rhythmNovelty(
      columns, (_noveltySpanSeconds / 2 / _tempogramStepSeconds).round());

  double timeOf(int k) =>
      _tempogramWindowSeconds / 2 + k * _tempogramStepSeconds;

  final suppress = (_peakSuppressSeconds / _tempogramStepSeconds).round();
  final refine = (_refineSeconds / _tempogramStepSeconds).round();
  final peaks = <MapEntry<double, double>>[];
  for (var k = 0; k < coarse.length; k++) {
    if (coarse[k] < _noveltyThreshold) continue;
    var isPeak = true;
    for (var o = math.max(0, k - suppress);
        o <= math.min(coarse.length - 1, k + suppress);
        o++) {
      if (coarse[o] > coarse[k] || (coarse[o] == coarse[k] && o < k)) {
        isPeak = false;
        break;
      }
    }
    if (!isPeak) continue;
    var best = k;
    for (var o = math.max(0, k - refine);
        o <= math.min(fine.length - 1, k + refine);
        o++) {
      if (fine[o] > fine[best]) best = o;
    }
    peaks.add(MapEntry(timeOf(best), coarse[k]));
  }
  peaks.sort((a, b) => b.value.compareTo(a.value));
  return peaks.map((p) => p.key).toList();
}

double _percentile(List<double> values, double p) {
  if (values.isEmpty) return 0;
  final sorted = List<double>.from(values)..sort();
  return sorted[((sorted.length - 1) * p).round()];
}
