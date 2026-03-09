import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaveformPlayer extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool enabled;
  final String? fileName;
  final VoidCallback onPlayPause;
  final VoidCallback onAddMarker;
  final ValueChanged<Duration> onSeek;

  const WaveformPlayer({
    super.key,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.enabled,
    required this.onPlayPause,
    required this.onAddMarker,
    required this.onSeek,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final maxMs = duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds;
    final progress = (position.inMilliseconds / maxMs).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Text(
            fileName ?? 'Selected audio',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '${_formatDuration(position)} / ${_formatDuration(duration)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _WaveformSeekArea(
            enabled: enabled,
            progress: progress,
            seed: fileName ?? 'wave',
            onSeekRatio: (ratio) {
              final ms = (duration.inMilliseconds * ratio).round();
              onSeek(Duration(milliseconds: ms));
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: enabled ? onPlayPause : null,
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(isPlaying ? 'Pause' : 'Play'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: enabled ? onAddMarker : null,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Marker At Current Time'),
            ),
          ],
        ),
      ],
    );
  }

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

class _WaveformSeekArea extends StatelessWidget {
  final bool enabled;
  final double progress;
  final String seed;
  final ValueChanged<double> onSeekRatio;

  const _WaveformSeekArea({
    required this.enabled,
    required this.progress,
    required this.seed,
    required this.onSeekRatio,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
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
  final Color background;
  final Color inactiveBar;
  final Color activeBar;

  _WaveformPainter({
    required this.progress,
    required this.seedHash,
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

    const bars = 90;
    const gap = 2.0;
    final totalGap = gap * (bars - 1);
    final barWidth = (size.width - totalGap) / bars;
    final centerY = size.height / 2;
    final progressX = size.width * progress;

    for (var i = 0; i < bars; i++) {
      final x = i * (barWidth + gap);
      final amp = _amplitude(i);
      final barHeight = math.max(10.0, size.height * amp);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, centerY - (barHeight / 2), barWidth, barHeight),
        const Radius.circular(2),
      );
      final barPaint = Paint()
        ..color = (x <= progressX) ? activeBar : inactiveBar;
      canvas.drawRRect(rect, barPaint);
    }

    final headPaint = Paint()
      ..color = activeBar
      ..strokeWidth = 2;
    canvas.drawLine(
        Offset(progressX, 0), Offset(progressX, size.height), headPaint);
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
        oldDelegate.background != background ||
        oldDelegate.inactiveBar != inactiveBar ||
        oldDelegate.activeBar != activeBar;
  }
}
