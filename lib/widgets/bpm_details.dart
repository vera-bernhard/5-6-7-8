import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/song_analysis.dart';
import '../services/audio_analysis.dart';

// The curve is computed once per analysis, the first time it is shown.
final _curves = Expando<Future<List<TempoPoint>>>();

/// Shows how the tempo changes over the song: a chart of the BPM every
/// second, and the BPM of each section.
Future<void> showBpmDetails(BuildContext context, SongAnalysis analysis) {
  return showDialog<void>(
    context: context,
    builder: (context) => _BpmDetailsDialog(analysis: analysis),
  );
}

class _BpmDetailsDialog extends StatelessWidget {
  final SongAnalysis analysis;

  const _BpmDetailsDialog({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);
    final columnStyle = textTheme.bodyMedium
        ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final curve = _curves[analysis] ??= tempoCurve(analysis);
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(l10n.bpmOverSong),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 180,
                child: FutureBuilder<List<TempoPoint>>(
                  future: curve,
                  builder: (context, snapshot) {
                    final points = snapshot.data;
                    if (points == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (points.isEmpty) {
                      return Center(child: Text(l10n.noClearBeat));
                    }
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _TempoChartPainter(
                        curve: points,
                        durationSeconds: analysis.durationSeconds,
                        lineColor: theme.colorScheme.primary,
                        gridColor: theme.colorScheme.outlineVariant,
                        labelStyle: textTheme.labelSmall!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textScaler: MediaQuery.textScalerOf(context),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.bpmChartNote,
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              for (final section in analysis.sections)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_formatSeconds(section.start)} – '
                          '${_formatSeconds(section.end)}',
                          style: columnStyle,
                        ),
                      ),
                      Text(
                        section.bpm > 0 ? '${section.bpm.round()} BPM' : '–',
                        style: columnStyle,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

String _formatSeconds(double seconds) {
  final total = seconds.round();
  return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
}

/// A line of the BPM over the song, with the BPM up the left side and the
/// time along the bottom. The line has a gap where the beat is unclear.
class _TempoChartPainter extends CustomPainter {
  final List<TempoPoint> curve;
  final double durationSeconds;
  final Color lineColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final TextScaler textScaler;

  // Points further apart than this are not connected.
  static const double _maxGapSeconds = 2;

  _TempoChartPainter({
    required this.curve,
    required this.durationSeconds,
    required this.lineColor,
    required this.gridColor,
    required this.labelStyle,
    required this.textScaler,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // BPM range: the data with some room, in whole steps of 10 or 20.
    final low = curve.map((p) => p.bpm).reduce(math.min) - 5;
    final high = curve.map((p) => p.bpm).reduce(math.max) + 5;
    final bpmStep = high - low > 60 ? 20.0 : 10.0;
    final bottomBpm = (low / bpmStep).floorToDouble() * bpmStep;
    final topBpm = (high / bpmStep).ceilToDouble() * bpmStep;

    // About four time labels, at whole minutes or other round values.
    final timeStep = const [15.0, 30.0, 60.0, 120.0, 300.0, 600.0]
        .firstWhere((step) => durationSeconds / step <= 4, orElse: () => 1200);

    final bpmLabels = [
      for (var bpm = bottomBpm; bpm <= topBpm; bpm += bpmStep)
        _label('${bpm.round()}'),
    ];
    final timeLabels = [
      for (var t = 0.0; t <= durationSeconds; t += timeStep)
        _label(_formatSeconds(t)),
    ];
    final axisWidth = bpmLabels.map((l) => l.width).reduce(math.max) + 8;
    final axisHeight = timeLabels.first.height + 6;
    final plot = Rect.fromLTRB(
      axisWidth,
      bpmLabels.first.height / 2,
      size.width - timeLabels.last.width / 2,
      size.height - axisHeight,
    );
    double x(double seconds) =>
        plot.left + seconds / durationSeconds * plot.width;
    double y(double bpm) =>
        plot.bottom - (bpm - bottomBpm) / (topBpm - bottomBpm) * plot.height;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < bpmLabels.length; i++) {
      final lineY = y(bottomBpm + i * bpmStep);
      canvas.drawLine(
          Offset(plot.left, lineY), Offset(plot.right, lineY), grid);
      final label = bpmLabels[i];
      label.paint(canvas,
          Offset(axisWidth - 8 - label.width, lineY - label.height / 2));
    }
    for (var i = 0; i < timeLabels.length; i++) {
      final label = timeLabels[i];
      label.paint(
          canvas, Offset(x(i * timeStep) - label.width / 2, plot.bottom + 6));
    }

    final path = Path();
    for (var i = 0; i < curve.length; i++) {
      final point = Offset(x(curve[i].seconds), y(curve[i].bpm));
      final connected =
          i > 0 && curve[i].seconds - curve[i - 1].seconds <= _maxGapSeconds;
      if (connected) {
        path.lineTo(point.dx, point.dy);
      } else {
        path.moveTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final label in [...bpmLabels, ...timeLabels]) {
      label.dispose();
    }
  }

  TextPainter _label(String text) => TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();

  @override
  bool shouldRepaint(covariant _TempoChartPainter oldDelegate) {
    return oldDelegate.curve != curve ||
        oldDelegate.durationSeconds != durationSeconds ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.textScaler != textScaler;
  }
}
