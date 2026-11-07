import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_format.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_provider.dart';

/// Awaits a pull-to-refresh reload. A failure is already on screen through
/// the provider's error state, so it is not thrown a second time here.
Future<void> studioRefresh(Future<Object?> reload) async {
  try {
    await reload;
  } on AppException {
    // Shown by the screen's error view.
  }
}

/// The 7 / 28 / 60 / 365-day picker every analytics screen shares.
class StudioRangeChips extends ConsumerWidget {
  const StudioRangeChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(studioRangeProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final d in studioRanges) ...[
            Chip2(
              key: Key('studio_range_$d'),
              label: '$d days',
              active: d == days,
              onTap: () => ref.read(studioRangeProvider.notifier).set(d),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// A titled card: the building block of every Studio screen.
class StudioSection extends StatelessWidget {
  const StudioSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: NowaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NowaColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: sora(size: 14.5))),
              ?trailing,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: work(size: 12, color: NowaColors.dim)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// "+40 (+50.0%)" coloured by direction.
class ChangeText extends StatelessWidget {
  const ChangeText({
    super.key,
    required this.current,
    required this.previous,
    this.size = 11.5,
  });

  final int current;
  final int previous;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sign = changeSign(current, previous);
    final color = sign > 0
        ? NowaColors.supportInk
        : sign < 0
            ? NowaColors.danger
            : NowaColors.dim;
    return Text(
      changeLine(current, previous),
      style: work(size: size, color: color, height: 1.2),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// One metric: label, value and its change on the window before. Tappable
/// when it drives a chart.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.previous,
    this.selected = false,
    this.onTap,
    this.display,
  });

  final String label;
  final int value;
  final int? previous;
  final bool selected;
  final VoidCallback? onTap;

  /// Shown instead of the compact number when set ("5.4s", "42%").
  final String? display;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: selected
              ? NowaColors.accent.withValues(alpha: 0.12)
              : NowaColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? NowaColors.accent : NowaColors.hairline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: work(size: 12, color: NowaColors.dim, height: 1.2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              display ?? _formatSigned(value),
              style: sora(size: 19, weight: FontWeight.w700),
            ),
            if (previous != null) ...[
              const SizedBox(height: 2),
              ChangeText(current: value, previous: previous!),
            ],
          ],
        ),
      ),
    );
  }
}

/// [compact] for a count that can be negative (net likes, net followers).
String _formatSigned(int n) => n < 0 ? '-${compact(-n)}' : compact(n);

/// Tiles two to a row. A plain Column of Rows: there are never more than a
/// handful, so a lazy grid would only add a scroll inside a scroll.
class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: 8),
                Expanded(
                  child: i + 1 < tiles.length
                      ? tiles[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

TextStyle get _axisStyle => work(size: 10, color: NowaColors.dim, height: 1);

FlGridData get _grid => FlGridData(
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: NowaColors.hairline, strokeWidth: 1),
    );

/// A daily series as a line, one label per few days under it.
class StudioLineChart extends StatelessWidget {
  const StudioLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 180,
    this.color = NowaColors.accent,
    this.formatY,
  });

  final List<double> values;

  /// One per value; only a few are drawn.
  final List<String> labels;
  final double height;
  final Color color;

  /// Axis and tooltip text for a value; a compact count by default.
  final String Function(double value)? formatY;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(height: height, child: const _EmptyChart());
    }
    final format = formatY ?? (v) => _formatSigned(v.round());
    final top = niceMax(values.reduce(math.max));
    final low = values.reduce(math.min);
    final bottom = low < 0 ? -niceMax(-low) : 0.0;
    final shown = labelIndexes(values.length).toSet();
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(1, values.length - 1).toDouble(),
          minY: bottom,
          maxY: top,
          gridData: _grid,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: (top - bottom) / 2,
                getTitlesWidget: (value, meta) =>
                    Text(format(value), style: _axisStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (value != i || !shown.contains(i) || i >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[i], style: _axisStyle),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => NowaColors.surfaceHigh,
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    '${labels.elementAtOrNull(s.x.round()) ?? ''}\n${format(s.y)}',
                    sora(size: 11.5),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i]),
              ],
              color: color,
              barWidth: 2.2,
              isCurved: values.length > 2,
              preventCurveOverShooting: true,
              dotData: FlDotData(show: values.length == 1),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical bars with a label under each (active hours, active days).
class StudioBarChart extends StatelessWidget {
  const StudioBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 160,
    this.labelEvery = 1,
  });

  final List<int> values;
  final List<String> labels;
  final double height;

  /// Draw every n-th label only — 24 hours do not fit side by side.
  final int labelEvery;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(height: height, child: const _EmptyChart());
    }
    final top = niceMax(values.reduce(math.max).toDouble());
    final busiest = values.reduce(math.max);
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: top,
          gridData: _grid,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: top / 2,
                getTitlesWidget: (value, meta) =>
                    Text(compact(value.round()), style: _axisStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i % labelEvery != 0 || i >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[i], style: _axisStyle),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => NowaColors.surfaceHigh,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${labels.elementAtOrNull(group.x) ?? ''}\n${compact(rod.toY.round())}',
                sora(size: 11.5),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i].toDouble(),
                    width: values.length > 12 ? 6 : 16,
                    color: values[i] == busiest && busiest > 0
                        ? NowaColors.accent
                        : NowaColors.support.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) => Center(
        child: Text('No data yet', style: work(size: 12, color: NowaColors.dim)),
      );
}

/// Labelled horizontal bars as shares of their total — traffic sources,
/// search queries, age groups.
class BarList extends StatelessWidget {
  const BarList({super.key, required this.rows, this.showPercent = true});

  final List<(String, int)> rows;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('No data yet', style: work(size: 12, color: NowaColors.dim)),
      );
    }
    final total = rows.fold<int>(0, (sum, r) => sum + r.$2);
    final most = rows.map((r) => r.$2).reduce(math.max);
    return Column(
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: work(size: 12.5, height: 1.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      showPercent && total > 0
                          ? formatPercent(value / total)
                          : compact(value),
                      style: sora(size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: most == 0 ? 0 : value / most,
                    minHeight: 5,
                    color: NowaColors.accent,
                    backgroundColor: NowaColors.surfaceHigh,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// What a breakdown says while the audience is too small to show it.
class NotEnoughData extends StatelessWidget {
  const NotEnoughData({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: NowaColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, color: NowaColors.dim, size: 22),
          const SizedBox(height: 8),
          Text(
            "You'll see this once there's enough data.",
            textAlign: TextAlign.center,
            style: work(size: 12.5, color: NowaColors.dim),
          ),
        ],
      ),
    );
  }
}

/// A small pill: a status ("Under review") or a mark ("Pinned").
class StudioBadge extends StatelessWidget {
  const StudioBadge(this.label, {super.key, this.color = NowaColors.dim});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: sora(size: 10, color: color)),
    );
  }
}

/// A video's thumbnail in the 3:4 box Studio lists use.
class StudioThumb extends StatelessWidget {
  const StudioThumb({super.key, required this.url, this.width = 54});

  final String? url;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: width * 4 / 3,
        child: RemoteImage(url: url, radius: 8, band: 5),
      );
}

/// One of the creator's videos as a list row: thumbnail, title, date, marks
/// and its counts.
class StudioPostTile extends StatelessWidget {
  const StudioPostTile({
    super.key,
    required this.video,
    this.onTap,
    this.trailing,
  });

  final VideoModel video;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final status = statusLabel(video.status);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudioThumb(url: video.thumbnailUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title.isEmpty ? 'Untitled' : video.title,
                    style: sora(size: 13, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${dateLabel(video.createdAt)} · ${visibilityLabel(video.visibility)}',
                    style: work(size: 11.5, color: NowaColors.dim, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (video.pinnedAt != null)
                        const StudioBadge('Pinned', color: NowaColors.supportInk),
                      if (status != null)
                        StudioBadge(status, color: NowaColors.danger),
                      _Count(Icons.play_arrow_rounded, video.viewCount),
                      _Count(Icons.favorite_rounded, video.likeCount),
                      _Count(Icons.chat_bubble_rounded, video.commentCount),
                    ],
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.icon, this.value);

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: NowaColors.dim),
          const SizedBox(width: 2),
          Text(compact(value), style: work(size: 11.5, color: NowaColors.dim)),
        ],
      );
}
