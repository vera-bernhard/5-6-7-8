import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/song_analysis.dart';

class WaveformPlayer extends StatelessWidget {
  final String? title;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool enabled;
  final VoidCallback onPlayPause;
  final VoidCallback? onSaveTimestamp;
  final VoidCallback onShufflePlay;
  final VoidCallback onShuffleReset;
  final VoidCallback onToggleSpeed;
  final String speedLabel;
  final bool shufflePlayEnabled;
  final int shuffleSectionsTotal;
  final int shuffleSectionsRemaining;
  final ValueChanged<Duration> onSeek;
  final String? waveformSeed;

  /// Loudness buckets of the real audio (0–255), or null to show a
  /// placeholder until the analysis is done.
  final Uint8List? waveform;
  final List<BpmSection> sections;
  final bool analyzing;

  /// Remaining silence of a silent lead-in/out, or null if none is running.
  final Duration? silenceRemaining;
  final Duration silenceTotal;
  final bool silenceIsLeadOut;

  const WaveformPlayer({
    super.key,
    this.title,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.enabled,
    required this.onPlayPause,
    this.onSaveTimestamp,
    required this.onShufflePlay,
    required this.onShuffleReset,
    required this.onToggleSpeed,
    required this.speedLabel,
    required this.shufflePlayEnabled,
    required this.shuffleSectionsTotal,
    required this.shuffleSectionsRemaining,
    required this.onSeek,
    this.waveformSeed,
    this.waveform,
    this.sections = const <BpmSection>[],
    this.analyzing = false,
    this.silenceRemaining,
    this.silenceTotal = Duration.zero,
    this.silenceIsLeadOut = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxMs = duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds;
    final progress = (position.inMilliseconds / maxMs).clamp(0.0, 1.0);
    final canSaveTimestamp = enabled && onSaveTimestamp != null;
    final silence = silenceRemaining;
    final durationSeconds = duration.inMilliseconds / 1000.0;
    final currentSection = _sectionAt(position.inMilliseconds / 1000.0);
    final textTheme = Theme.of(context).textTheme;
    final showBand = sections.isNotEmpty && durationSeconds > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium,
                ),
              ),
              if (analyzing) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                const SizedBox(width: 4),
                Text('Analyzing', style: textTheme.bodySmall),
              ],
              const SizedBox(width: 8),
              Text(
                silence != null && !silenceIsLeadOut
                    ? '-${_formatDuration(_ceilToSecond(silence))} / ${_formatDuration(duration)}'
                    : '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (showBand)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: _BpmBand(
              sections: sections,
              durationSeconds: durationSeconds,
              currentSection: currentSection,
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Stack(
            children: [
              _WaveformSeekArea(
                enabled: enabled,
                progress: progress,
                seed: waveformSeed ?? 'wave',
                waveform: waveform,
                boundaries: durationSeconds > 0
                    ? sections
                        .skip(1)
                        .map((section) => section.start / durationSeconds)
                        .toList()
                    : const <double>[],
                onSeekRatio: (ratio) {
                  final ms = (duration.inMilliseconds * ratio).round();
                  onSeek(Duration(milliseconds: ms));
                },
              ),
              if (silence != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _SilenceOverlay(
                      remaining: silence,
                      total: silenceTotal,
                      isLeadOut: silenceIsLeadOut,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: canSaveTimestamp ? onSaveTimestamp : null,
              tooltip: 'Save Timestamp',
              icon: const Icon(Icons.bookmark_add),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: enabled ? onPlayPause : null,
              tooltip:
                  silence != null ? 'Stop' : (isPlaying ? 'Pause' : 'Play'),
              icon: Icon(silence != null
                  ? Icons.stop
                  : (isPlaying ? Icons.pause : Icons.play_arrow)),
            ),
            const SizedBox(width: 10),
            _ShuffleRingButton(
              enabled: enabled,
              shufflePlayEnabled: shufflePlayEnabled,
              totalSections: shuffleSectionsTotal,
              remainingSections: shuffleSectionsRemaining,
              onTap: onShufflePlay,
              onLongPress: onShuffleReset,
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                  onPressed: enabled ? onToggleSpeed : null,
                  tooltip: 'Speed $speedLabel',
                  icon: const Icon(Icons.speed),
                ),
                const SizedBox(width: 4),
                Text(
                  speedLabel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  BpmSection? _sectionAt(double seconds) {
    for (final section in sections) {
      if (seconds >= section.start && seconds < section.end) return section;
    }
    return null;
  }

  static Duration _ceilToSecond(Duration d) =>
      Duration(seconds: (d.inMilliseconds / 1000).ceil());

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds;
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _ShuffleRingButton extends StatelessWidget {
  final bool enabled;
  final bool shufflePlayEnabled;
  final int totalSections;
  final int remainingSections;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ShuffleRingButton({
    required this.enabled,
    required this.shufflePlayEnabled,
    required this.totalSections,
    required this.remainingSections,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && shufflePlayEnabled;
    final canLongPress = enabled && totalSections > 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Shuffle ($remainingSections/$totalSections left)',
      child: Material(
        color: colorScheme.secondaryContainer,
        shape: const CircleBorder(),
        child: InkResponse(
          onTap: enabled ? onTap : null,
          onLongPress: canLongPress ? onLongPress : null,
          radius: 20,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(40),
                  painter: _ShuffleRadialPainter(
                    totalSections: totalSections,
                    remainingSections: remainingSections,
                    filledColor: colorScheme.primary,
                    emptyColor: colorScheme.surfaceContainerHighest,
                    fallbackTrackColor: colorScheme.outlineVariant,
                  ),
                ),
                Icon(
                  Icons.shuffle,
                  size: 20,
                  color: enabled
                      ? (canTap ? colorScheme.primary : colorScheme.outline)
                      : colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShuffleRadialPainter extends CustomPainter {
  final int totalSections;
  final int remainingSections;
  final Color filledColor;
  final Color emptyColor;
  final Color fallbackTrackColor;

  _ShuffleRadialPainter({
    required this.totalSections,
    required this.remainingSections,
    required this.filledColor,
    required this.emptyColor,
    required this.fallbackTrackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) / 2) - 3;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = fallbackTrackColor;

    if (totalSections <= 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, basePaint);
      return;
    }

    final clampedRemaining = remainingSections.clamp(0, totalSections);
    final perSection = (math.pi * 2) / totalSections;
    final gap = math.min(0.24, perSection * 0.35);
    final sweep = math.max(0.02, perSection - gap);

    for (var i = 0; i < totalSections; i++) {
      final start = (-math.pi / 2) + (i * perSection) + (gap / 2);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = i < clampedRemaining ? filledColor : emptyColor;
      canvas.drawArc(rect, start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShuffleRadialPainter oldDelegate) {
    return oldDelegate.totalSections != totalSections ||
        oldDelegate.remainingSections != remainingSections ||
        oldDelegate.filledColor != filledColor ||
        oldDelegate.emptyColor != emptyColor ||
        oldDelegate.fallbackTrackColor != fallbackTrackColor;
  }
}

class _SilenceOverlay extends StatelessWidget {
  final Duration remaining;
  final Duration total;
  final bool isLeadOut;

  const _SilenceOverlay({
    required this.remaining,
    required this.total,
    required this.isLeadOut,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    final totalMs = total.inMilliseconds <= 0 ? 1 : total.inMilliseconds;
    final elapsed = (1 - remaining.inMilliseconds / totalMs).clamp(0.0, 1.0);
    // Fraction of the current second that has passed, used to pulse the number.
    final secondFraction = 1 - (remaining.inMilliseconds % 1000) / 1000;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: colors.surface.withValues(alpha: 0.82),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLeadOut ? 'Ending in' : 'Starting in',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Transform.scale(
                      scale: 1.25 - 0.25 * secondFraction,
                      child: Text(
                        '$seconds',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            LinearProgressIndicator(value: elapsed, minHeight: 4),
          ],
        ),
      ),
    );
  }
}

class _WaveformSeekArea extends StatelessWidget {
  final bool enabled;
  final double progress;
  final String seed;
  final Uint8List? waveform;
  final List<double> boundaries;
  final ValueChanged<double> onSeekRatio;

  const _WaveformSeekArea({
    required this.enabled,
    required this.progress,
    required this.seed,
    required this.waveform,
    required this.boundaries,
    required this.onSeekRatio,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: enabled
                ? (details) {
                    final ratio =
                        (details.localPosition.dx / constraints.maxWidth)
                            .clamp(0.0, 1.0);
                    onSeekRatio(ratio);
                  }
                : null,
            onHorizontalDragUpdate: enabled
                ? (details) {
                    final ratio =
                        (details.localPosition.dx / constraints.maxWidth)
                            .clamp(0.0, 1.0);
                    onSeekRatio(ratio);
                  }
                : null,
            child: CustomPaint(
              painter: _WaveformPainter(
                progress: progress,
                seedHash: seed.hashCode,
                waveform: waveform,
                boundaries: boundaries,
                boundaryColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.45),
                background:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                inactiveBar: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.28),
                activeBar: Theme.of(context).colorScheme.primary,
              ),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final int seedHash;
  final Uint8List? waveform;

  final List<double> boundaries;
  final Color boundaryColor;
  final Color background;
  final Color inactiveBar;
  final Color activeBar;

  _WaveformPainter({
    required this.progress,
    required this.seedHash,
    required this.waveform,
    required this.boundaries,
    required this.boundaryColor,
    required this.background,
    required this.inactiveBar,
    required this.activeBar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = background;
    final border = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas.drawRRect(border, bgPaint);

    const bars = 200;
    const gap = 1.2;
    final totalGap = gap * (bars - 1);
    final barWidth = (size.width - totalGap) / bars;
    final centerY = size.height / 2;
    final progressX = size.width * progress;
    final real = waveform != null && waveform!.isNotEmpty;
    // The placeholder is drawn faintly until the real waveform is ready.
    final placeholderAlpha = real ? 1.0 : 0.45;

    for (var i = 0; i < bars; i++) {
      final x = i * (barWidth + gap);
      final amp = real ? _realAmplitude(i, bars) : _amplitude(i);
      final barHeight = math.max(3.0, size.height * 0.92 * amp);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, centerY - (barHeight / 2), barWidth, barHeight),
        const Radius.circular(2),
      );
      final color = (x <= progressX) ? activeBar : inactiveBar;
      final barPaint = Paint()
        ..color = color.withValues(alpha: color.a * placeholderAlpha);
      canvas.drawRRect(rect, barPaint);
    }

    final boundaryPaint = Paint()
      ..color = boundaryColor
      ..strokeWidth = 1;
    for (final ratio in boundaries) {
      final x = size.width * ratio;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), boundaryPaint);
    }

    final headPaint = Paint()
      ..color = activeBar
      ..strokeWidth = 2;
    canvas.drawLine(
        Offset(progressX, 0), Offset(progressX, size.height), headPaint);
  }

  /// Mean loudness of the waveform buckets that fall into bar [i].
  double _realAmplitude(int i, int bars) {
    final data = waveform!;
    final from = (i * data.length / bars).floor();
    final to = math.max(from + 1, ((i + 1) * data.length / bars).floor());
    var sum = 0;
    for (var b = from; b < to && b < data.length; b++) {
      sum += data[b];
    }
    return (sum / (to - from) / 255).clamp(0.0, 1.0);
  }

  double _amplitude(int i) {
    final phase = (seedHash % 31) * 0.07;
    final s1 = (math.sin(i * 0.35 + phase) + 1) / 2;
    final s2 = (math.cos(i * 0.17 + phase * 0.6) + 1) / 2;
    return (0.2 + (s1 * 0.5) + (s2 * 0.3)).clamp(0.15, 1.0);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.seedHash != seedHash ||
        oldDelegate.waveform != waveform ||
        !listEquals(oldDelegate.boundaries, boundaries) ||
        oldDelegate.boundaryColor != boundaryColor ||
        oldDelegate.background != background ||
        oldDelegate.inactiveBar != inactiveBar ||
        oldDelegate.activeBar != activeBar;
  }
}

/// A strip above the waveform with one block per detected music section,
/// labelled with its BPM.
class _BpmBand extends StatelessWidget {
  final List<BpmSection> sections;
  final double durationSeconds;
  final BpmSection? currentSection;

  const _BpmBand({
    required this.sections,
    required this.durationSeconds,
    required this.currentSection,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return SizedBox(
      height: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            children: [
              for (var i = 0; i < sections.length; i++)
                _buildBlock(
                  context,
                  sections[i],
                  i,
                  width,
                  colors,
                  labelStyle,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBlock(BuildContext context, BpmSection section, int index,
      double width, ColorScheme colors, TextStyle? labelStyle) {
    final left = (section.start / durationSeconds).clamp(0.0, 1.0) * width;
    final right = (section.end / durationSeconds).clamp(0.0, 1.0) * width;
    final blockWidth = math.max(0.0, right - left - 1);
    final isCurrent = identical(section, currentSection);
    final style = labelStyle?.copyWith(
      color: isCurrent ? colors.onPrimaryContainer : colors.onSurfaceVariant,
    );
    // The unit is shown once, in the last block, if it fits there.
    final isLast = index == sections.length - 1;
    final candidates = section.bpm <= 0
        ? const <String>[]
        : [
            if (isLast) '${section.bpm.round()} BPM',
            '${section.bpm.round()}',
          ];
    // Hide the number in blocks too narrow for it, instead of clipping it.
    String? label;
    for (final candidate in candidates) {
      if (_textWidth(context, candidate, style) + 6 <= blockWidth) {
        label = candidate;
        break;
      }
    }
    final background = isCurrent
        ? colors.primaryContainer
        : (index.isEven
            ? colors.surfaceContainerHigh
            : colors.surfaceContainerHighest);
    return Positioned(
      left: left,
      width: blockWidth,
      top: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: label == null
            ? null
            : Text(label, maxLines: 1, softWrap: false, style: style),
      ),
    );
  }

  static double _textWidth(
      BuildContext context, String text, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}
