import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/settings/data/settings_models.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_provider.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_rules.dart';

/// Screen time → Summary: one of the last four weeks, day and night time
/// stacked per day. [initialWeek] — a Monday, from a weekly screen-time
/// notification — is selected when it is one of the four.
class ScreenTimeSummaryScreen extends ConsumerStatefulWidget {
  const ScreenTimeSummaryScreen({super.key, this.initialWeek});

  final String? initialWeek;

  @override
  ConsumerState<ScreenTimeSummaryScreen> createState() =>
      _ScreenTimeSummaryScreenState();
}

class _ScreenTimeSummaryScreenState
    extends ConsumerState<ScreenTimeSummaryScreen> {
  late final _weeks = lastFourWeeks(DateTime.now());
  late String _week = _weeks.any((w) => w.start == widget.initialWeek)
      ? widget.initialWeek!
      : _weeks.last.start;

  @override
  Widget build(BuildContext context) {
    final provider = screenTimeWeekProvider(_week);
    final week = ref.watch(provider);
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Summary'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        children: [
          Text(
            'Your weekly metrics include your time on the app and on nowa.com.',
            style: work(size: 13, height: 1.5, color: NowaColors.dim),
          ),
          const SizedBox(height: 18),
          const SectionLabel('SELECT WEEK'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: NowaColors.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('summary_week_picker'),
                value: _week,
                isExpanded: true,
                dropdownColor: NowaColors.surfaceHigh,
                style: work(size: 14),
                items: [
                  for (final w in _weeks)
                    DropdownMenuItem(value: w.start, child: Text(w.label)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _week = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Time spent', style: sora(size: 15)),
          const SizedBox(height: 14),
          week.when(
            loading: () => const SizedBox(height: 260, child: LoadingView()),
            error: (error, _) => ErrorView(
              message: settingsErrorMessage(error),
              onRetry: () => ref.invalidate(provider),
            ),
            data: (data) => _WeekChart(week: data),
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatefulWidget {
  const _WeekChart({required this.week});

  final ScreenTimeWeek week;

  @override
  State<_WeekChart> createState() => _WeekChartState();
}

class _WeekChartState extends State<_WeekChart> {
  int? _selected;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _chartHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    final days = widget.week.days;
    final maxSeconds = days.fold<int>(
      0,
      (m, d) => d.totalSeconds > m ? d.totalSeconds : m,
    );
    final top = axisTop(maxSeconds);
    final ticks = axisTicks(maxSeconds);
    final daySum = days.fold<int>(0, (s, d) => s + d.daySeconds);
    final nightSum = days.fold<int>(0, (s, d) => s + d.nightSeconds);
    final total = daySum + nightSum;
    final selected = _selected == null || _selected! >= days.length
        ? null
        : days[_selected!];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 20,
          child: selected == null
              ? null
              : Text(
                  'Day: ${formatDuration(selected.daySeconds)}   '
                  'Night: ${formatDuration(selected.nightSeconds)}',
                  key: const Key('summary_tooltip'),
                  style: work(size: 12.5, color: NowaColors.dim),
                ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: _chartHeight + 34,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gridline labels, top first, then the baseline.
              SizedBox(
                width: 44,
                height: _chartHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final t in [...ticks, 0.0])
                      Text(
                        '${t.toStringAsFixed(1)}m',
                        style: work(size: 10, color: NowaColors.dim),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: _chartHeight,
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (var i = 0; i <= ticks.length; i++)
                                const Divider(
                                  height: 1,
                                  color: NowaColors.hairline,
                                ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < days.length; i++)
                                Expanded(
                                  child: GestureDetector(
                                    key: Key('summary_bar_$i'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => setState(() => _selected = i),
                                    child: _Bar(
                                      day: days[i],
                                      top: top,
                                      height: _chartHeight,
                                      highlighted: _selected == i,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var i = 0; i < days.length; i++)
                          Expanded(
                            child: Text(
                              '${_weekdays[i]}\n${_dayOfMonth(days[i].date)}',
                              textAlign: TextAlign.center,
                              style: work(
                                size: 10,
                                height: 1.2,
                                color: NowaColors.dim,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _LegendRow(
          color: NowaColors.screenDay,
          label: 'Day time',
          info: 'Day time is between 6 AM–10 PM.',
          share: total == 0 ? 0 : daySum / total,
          seconds: daySum,
        ),
        const SizedBox(height: 10),
        _LegendRow(
          color: NowaColors.screenNight,
          label: 'Night time',
          info: 'Night time is between 10 PM–6 AM.',
          share: total == 0 ? 0 : nightSum / total,
          seconds: nightSum,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('Total', style: sora(size: 14)),
            const Spacer(),
            Text(
              formatDuration(total),
              key: const Key('summary_total'),
              style: sora(size: 14),
            ),
          ],
        ),
      ],
    );
  }

  static String _dayOfMonth(String date) =>
      int.tryParse(date.split('-').last)?.toString() ?? '';
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.top,
    required this.height,
    required this.highlighted,
  });

  final ScreenTimeDay day;
  final double top;
  final double height;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    double h(int seconds) => top <= 0 ? 0 : seconds / top * height;
    return Center(
      child: SizedBox(
        width: 18,
        child: Opacity(
          opacity: highlighted ? 1 : 0.85,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: h(day.nightSeconds),
                decoration: const BoxDecoration(
                  color: NowaColors.screenNight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              Container(height: h(day.daySeconds), color: NowaColors.screenDay),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.info,
    required this.share,
    required this.seconds,
  });

  final Color color;
  final String label;
  final String info;
  final double share;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: work(size: 13.5)),
        const SizedBox(width: 4),
        Tooltip(
          message: info,
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(Icons.info_outline, size: 15, color: NowaColors.dim),
        ),
        const SizedBox(width: 10),
        if (share > 0)
          Container(
            width: 90 * share,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const Spacer(),
        Text(formatDuration(seconds), style: work(size: 13.5)),
      ],
    );
  }
}
