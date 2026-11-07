import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_format.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_provider.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_widgets.dart';

/// One video's analytics: lifetime totals, the window's numbers against the
/// window before, retention, where views came from and who watched.
class StudioVideoAnalyticsScreen extends ConsumerStatefulWidget {
  const StudioVideoAnalyticsScreen({super.key, required this.videoId});

  final String videoId;

  @override
  ConsumerState<StudioVideoAnalyticsScreen> createState() =>
      _StudioVideoAnalyticsScreenState();
}

class _StudioVideoAnalyticsScreenState
    extends ConsumerState<StudioVideoAnalyticsScreen> {
  String _metric = 'views';

  @override
  Widget build(BuildContext context) {
    final provider = studioVideoAnalyticsProvider(widget.videoId);
    final analytics = ref.watch(provider);
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: NowaAppBar(
        title: 'Video analytics',
        actions: [
          IconButton(
            tooltip: 'Comments',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () =>
                context.push('/studio/comments?videoId=${widget.videoId}'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: NowaColors.accent,
        onRefresh: () => studioRefresh(ref.refresh(provider.future)),
        child: analytics.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e is ServerException && e.code == 'VIDEO_NOT_FOUND'
                ? 'This video is gone, or it is not yours.'
                : e.toString(),
            onRetry: () => ref.invalidate(provider),
          ),
          data: (data) => _body(context, data),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, StudioVideoAnalytics data) {
    final d = data.detail;
    final video = data.video;
    final windowMetrics = [
      ('views', 'Views', d.current.views, d.previous.views, (CreatorDailyStats x) => x.views),
      ('likes', 'Likes', d.current.likes, d.previous.likes, (CreatorDailyStats x) => x.likes),
      ('comments', 'Comments', d.current.comments, d.previous.comments, (CreatorDailyStats x) => x.comments),
      ('shares', 'Shares', d.current.shares, d.previous.shares, (CreatorDailyStats x) => x.shares),
      ('saves', 'Saves', d.current.saves, d.previous.saves, (CreatorDailyStats x) => x.saves),
      ('followers', 'New followers', d.current.newFollowers, d.previous.newFollowers, (CreatorDailyStats x) => x.followersGained),
    ];
    final selected = windowMetrics.firstWhere((m) => m.$1 == _metric);
    final dropAt = retentionInsight(d.retention);
    final audience = d.audience;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Header: the video itself.
        InkWell(
          onTap: () => context.push('/video/${video.id}'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudioThumb(url: video.thumbnailUrl, width: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title.isEmpty ? 'Untitled' : video.title,
                      style: sora(size: 14, height: 1.3),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Posted ${dateLabel(video.createdAt)}',
                      style: work(size: 12, color: NowaColors.dim),
                    ),
                    if (statusLabel(video.status) case final status?) ...[
                      const SizedBox(height: 6),
                      StudioBadge(status, color: NowaColors.danger),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StudioSection(
          title: 'Lifetime',
          child: MetricGrid(
            tiles: [
              MetricTile(label: 'Views', value: d.views),
              MetricTile(label: 'Viewers', value: d.viewers),
              MetricTile(
                label: 'Total watch time',
                value: d.totalWatchMs,
                display: formatWatchTime(d.totalWatchMs),
              ),
              MetricTile(
                label: 'Average watch time',
                value: d.avgWatchMs,
                display: formatWatchTime(d.avgWatchMs),
              ),
              MetricTile(
                label: 'Watched full video',
                value: 0,
                display: formatPercent(d.completionRate),
              ),
              MetricTile(label: 'New followers', value: d.newFollowers),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const StudioRangeChips(),
        const SizedBox(height: 12),
        MetricGrid(
          tiles: [
            for (final m in windowMetrics)
              MetricTile(
                label: m.$2,
                value: m.$3,
                previous: m.$4,
                selected: m.$1 == _metric,
                onTap: () => setState(() => _metric = m.$1),
              ),
          ],
        ),
        const SizedBox(height: 12),
        StudioSection(
          title: selected.$2,
          subtitle: 'By day',
          child: StudioLineChart(
            values: [for (final x in d.daily) selected.$5(x).toDouble()],
            labels: [for (final x in d.daily) dayLabel(x.day)],
          ),
        ),
        const SizedBox(height: 16),
        StudioSection(
          title: 'Retention',
          subtitle: dropAt == null
              ? 'Share of views still watching, across the video'
              : 'Most viewers stop watching around ${dropAt * 5}% of the way in',
          child: StudioLineChart(
            values: d.retention,
            labels: [for (var i = 0; i < d.retention.length; i++) '${i * 5}%'],
            color: NowaColors.support,
            formatY: formatPercent,
          ),
        ),
        const SizedBox(height: 16),
        StudioSection(
          title: 'Traffic sources',
          subtitle: 'Where viewers found this video',
          child: BarList(
            rows: [
              for (final t in d.trafficSources)
                (trafficSourceLabel(t.source), t.views),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StudioSection(
          title: 'Search queries',
          subtitle: 'What viewers searched to find it',
          child: BarList(
            rows: [for (final q in d.searchQueries) (q.query, q.views)],
          ),
        ),
        const SizedBox(height: 16),
        StudioSection(
          title: 'Viewers',
          subtitle: rangeLabel(ref.watch(studioRangeProvider)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetricGrid(
                tiles: [
                  MetricTile(
                    label: 'Total viewers',
                    value: audience.total,
                    previous: audience.previousTotal,
                  ),
                  MetricTile(
                    label: 'New viewers',
                    value: audience.newViewers,
                    previous: audience.previousNewViewers,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!audience.breakdownAvailable)
                const NotEnoughData()
              else ...[
                Text('Viewer types', style: sora(size: 12.5)),
                const SizedBox(height: 8),
                BarList(
                  rows: [
                    ('Returning viewers', audience.returning ?? 0),
                    ('New viewers', audience.newViewers),
                  ],
                ),
                BarList(
                  rows: [
                    ('Followers', audience.followers ?? 0),
                    ('Non-followers', audience.nonFollowers ?? 0),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Age', style: sora(size: 12.5)),
                const SizedBox(height: 8),
                BarList(
                  rows: [
                    for (final (key, label) in ageGroups)
                      (label, audience.ageGroups?[key] ?? 0),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
