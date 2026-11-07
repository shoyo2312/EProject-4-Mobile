import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_format.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_provider.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_widgets.dart';

/// Analytics, in the three tabs TikTok Studio's header carries. Followers has
/// no backend yet, so it is left out, as on the web.
class StudioAnalyticsScreen extends StatelessWidget {
  const StudioAnalyticsScreen({
    super.key,
    this.initialTab = 0,
    this.initialMetric,
  });

  final int initialTab;

  /// Which overview metric the chart starts on (`views`, `likes`, …).
  final String? initialMetric;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Scaffold(
        backgroundColor: NowaColors.bg,
        appBar: const NowaAppBar(title: 'Analytics'),
        body: Column(
          children: [
            TabBar(
              indicatorColor: NowaColors.accent,
              labelColor: NowaColors.text,
              unselectedLabelColor: NowaColors.dim,
              labelStyle: sora(size: 13),
              dividerColor: NowaColors.hairline,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Content'),
                Tab(text: 'Viewers'),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: StudioRangeChips(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(initialMetric: initialMetric),
                  const _ContentTab(),
                  const _ViewersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerStatefulWidget {
  const _OverviewTab({this.initialMetric});

  final String? initialMetric;

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  late String _metric = widget.initialMetric ?? 'views';

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(studioOverviewProvider);
    return RefreshIndicator(
      color: NowaColors.accent,
      onRefresh: () => studioRefresh(ref.refresh(studioOverviewProvider.future)),
      child: overview.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(studioOverviewProvider),
        ),
        data: (data) {
          final metrics = overviewMetrics(data);
          final selected = metrics.firstWhere(
            (m) => m.key == _metric,
            orElse: () => metrics.first,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              MetricGrid(
                tiles: [
                  for (final m in metrics)
                    MetricTile(
                      key: Key('studio_overview_${m.key}'),
                      label: m.label,
                      value: m.value,
                      previous: m.previous,
                      selected: m.key == selected.key,
                      onTap: () => setState(() => _metric = m.key),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              StudioSection(
                title: selected.label,
                subtitle: 'By day, ${rangeLabel(data.daily.length).toLowerCase()}',
                child: StudioLineChart(
                  values: selected.series,
                  labels: [for (final d in data.daily) dayLabel(d.day)],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Likes, comments and saves are net: an unlike or a deleted '
                'comment in the window counts against it.',
                style: work(size: 11.5, color: NowaColors.dim),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContentTab extends ConsumerStatefulWidget {
  const _ContentTab();

  @override
  ConsumerState<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends ConsumerState<_ContentTab> {
  CreatorVideoSort _sort = CreatorVideoSort.views;

  int _valueOf(CreatorVideoStats row) => switch (_sort) {
        CreatorVideoSort.views => row.views,
        CreatorVideoSort.viewers => row.viewers,
        CreatorVideoSort.newViewers => row.newViewers,
        CreatorVideoSort.likes => row.likes,
        CreatorVideoSort.comments => row.comments,
        CreatorVideoSort.shares => row.shares,
      };

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(studioTopVideosProvider(_sort));
    final videos = ref.watch(studioVideoCacheProvider);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              for (final s in CreatorVideoSort.values) ...[
                ChoiceChip(
                  key: Key('studio_content_sort_${s.name}'),
                  label: Text(s.label),
                  selected: s == _sort,
                  onSelected: (_) => setState(() => _sort = s),
                  labelStyle: work(size: 12, height: 1),
                  selectedColor: NowaColors.accent.withValues(alpha: 0.25),
                  backgroundColor: NowaColors.surfaceHigh,
                  side: const BorderSide(color: NowaColors.hairline),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: NowaColors.accent,
            onRefresh: () => studioRefresh(ref.refresh(studioTopVideosProvider(_sort).future)),
            child: rows.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(studioTopVideosProvider(_sort)),
              ),
              data: (list) => list.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'None of your videos had activity in this window.',
                            textAlign: TextAlign.center,
                            style: work(size: 13, color: NowaColors.dim),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final row = list[i];
                        final video = videos[row.videoId];
                        return InkWell(
                          onTap: () =>
                              context.push('/studio/analytics/${row.videoId}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  child: Text('${i + 1}',
                                      style: sora(size: 13, color: NowaColors.dim)),
                                ),
                                StudioThumb(url: video?.thumbnailUrl, width: 44),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        video?.title ?? 'Video unavailable',
                                        style: sora(size: 13, height: 1.3),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${compact(row.views)} views · '
                                        '${compact(row.likes)} likes · '
                                        '${compact(row.comments)} comments',
                                        style: work(size: 11.5, color: NowaColors.dim),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(compact(_valueOf(row)),
                                        style: sora(size: 15, weight: FontWeight.w700)),
                                    Text(_sort.label.toLowerCase(),
                                        style: work(size: 10.5, color: NowaColors.dim)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewersTab extends ConsumerWidget {
  const _ViewersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewers = ref.watch(studioViewersProvider);
    return RefreshIndicator(
      color: NowaColors.accent,
      onRefresh: () => studioRefresh(ref.refresh(studioViewersProvider.future)),
      child: viewers.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(studioViewersProvider),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            MetricGrid(
              tiles: [
                MetricTile(
                  label: 'Total viewers',
                  value: data.totalViewers,
                  previous: data.previousTotalViewers,
                ),
                MetricTile(
                  label: 'New viewers',
                  value: data.newViewers,
                  previous: data.previousNewViewers,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Signed-in viewers only. New viewers watched you for the first time in this window.',
              style: work(size: 11.5, color: NowaColors.dim),
            ),
            const SizedBox(height: 16),
            StudioSection(
              title: 'Most active times',
              subtitle: 'Viewers by hour of day (Vietnam time)',
              child: data.breakdownAvailable && data.activeHours != null
                  ? StudioBarChart(
                      values: data.activeHours!,
                      labels: [for (var h = 0; h < 24; h++) '${h}h'],
                      labelEvery: 4,
                    )
                  : const NotEnoughData(),
            ),
            const SizedBox(height: 16),
            StudioSection(
              title: 'Most active days',
              subtitle: 'Viewers by day of the week',
              child: data.breakdownAvailable && data.activeDays != null
                  ? StudioBarChart(
                      values: data.activeDays!,
                      labels: weekdayLabels,
                    )
                  : const NotEnoughData(),
            ),
          ],
        ),
      ),
    );
  }
}
