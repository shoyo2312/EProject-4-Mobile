import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/constants/env.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/app_share.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/share_to_chat.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// Resolves to true when the viewer shared the link outside the app — that,
/// and not opening the sheet, is what the caller counts as a share
/// (interaction doc 3.7). Handing the link to another app or copying it both
/// count. A video sent into a chat resolves to false: chat-service counts
/// those itself, and counting here too would count it twice.
///
/// [saved] and [onToggleSave] drive the "Add to favorites" row, which is the
/// same save as the bookmark on the rail.
Future<bool> showShareSheet(
  BuildContext context, {
  required VideoModel video,
  bool saved = false,
  VoidCallback? onToggleSave,
}) async {
  final shared = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) =>
        _ShareSheet(video: video, saved: saved, onToggleSave: onToggleSave),
  );
  return shared ?? false;
}

/// The page on the web app that plays this video.
String videoShareLink(VideoModel video) =>
    '${Env.webBaseUrl}/video/${video.id}';

class _Target {
  const _Target({
    required this.app,
    required this.label,
    required this.logo,
    required this.colors,
  });

  final ShareApp app;
  final String label;

  /// White-filled glyph from `assets/share_icons/` (Simple Icons).
  final String logo;

  /// One colour for a flat tile, several for the brand's gradient.
  final List<Color> colors;
}

const _targets = <_Target>[
  _Target(
    app: ShareApp.zalo,
    label: 'Zalo',
    logo: 'assets/share_icons/zalo.svg',
    colors: [Color(0xFF0068FF)],
  ),
  _Target(
    app: ShareApp.messenger,
    label: 'Messenger',
    logo: 'assets/share_icons/messenger.svg',
    colors: [Color(0xFF0099FF), Color(0xFFA033FF), Color(0xFFFF5280)],
  ),
  _Target(
    app: ShareApp.instagram,
    label: 'Instagram',
    logo: 'assets/share_icons/instagram.svg',
    colors: [
      Color(0xFFFEDA75),
      Color(0xFFFA7E1E),
      Color(0xFFD62976),
      Color(0xFF962FBF),
      Color(0xFF4F5BD5),
    ],
  ),
  _Target(
    app: ShareApp.facebook,
    label: 'Facebook',
    logo: 'assets/share_icons/facebook.svg',
    colors: [Color(0xFF0866FF)],
  ),
];

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({
    required this.video,
    required this.saved,
    required this.onToggleSave,
  });

  final VideoModel video;
  final bool saved;
  final VoidCallback? onToggleSave;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  /// The whole conversation list, opened from "Messages", instead of the
  /// row of recent people and the other apps.
  bool _browsing = false;
  String _query = '';

  /// Conversation ids, in the order they were picked.
  final _picked = <String>[];
  final _note = TextEditingController();
  bool _sending = false;

  /// Kept across retries of the same share, so a lost answer cannot become
  /// a second message.
  final _attempt = newClientRequestId();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// The link alone: Facebook drops any text around a URL, and every other
  /// app turns a bare link into a preview card anyway.
  String get _link => videoShareLink(widget.video);

  Future<void> _shareTo(ShareApp app) async {
    final shared = await AppShare.shareTo(app, _link);
    if (shared && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _shareMore() async {
    final shared = await AppShare.shareWithSystem(_link);
    if (shared && mounted) Navigator.of(context).pop(true);
  }

  void _openMessages(bool signedIn) {
    if (!signedIn) {
      final router = GoRouter.of(context);
      Navigator.of(context).pop(false);
      router.push('/login');
      return;
    }
    setState(() => _browsing = true);
  }

  void _toggle(String conversationId) {
    setState(() {
      if (!_picked.remove(conversationId)) {
        if (_picked.length >= shareMaxRecipients) {
          NowaToast.of(
            context,
          ).info('You can send to up to $shareMaxRecipients people at once');
          return;
        }
        _picked.add(conversationId);
      }
    });
  }

  /// Each picked person gets the video as a message in their own chat. One
  /// failing does not take back the others; the sheet stays open on the
  /// ones that failed, so they can be tried again.
  Future<void> _send(Map<String, String> names) async {
    if (_picked.isEmpty || _sending) return;
    setState(() => _sending = true);
    final repository = ref.read(chatRepositoryProvider);
    final note = _note.text.trim();
    final failures = <String, String>{};
    final todo = [..._picked];
    // A few at a time, like the web client.
    for (var i = 0; i < todo.length; i += 3) {
      await Future.wait([
        for (final id in todo.skip(i).take(3))
          () async {
            try {
              final message = await repository.sendVideo(
                id,
                widget.video.id,
                note: note,
                clientRequestId: '$_attempt:$id',
              );
              if (ref.exists(conversationsProvider)) {
                ref.read(conversationsProvider.notifier).sent(message);
              }
            } on AppException catch (e) {
              failures[id] = shareFailure(e);
            }
          }(),
      ]);
    }
    if (!mounted) return;
    final toast = NowaToast.of(context);
    if (failures.isEmpty) {
      Navigator.of(context).pop(false);
      toast.success(
        todo.length == 1 ? 'Sent' : 'Sent to ${todo.length} people',
      );
      return;
    }
    setState(() {
      _sending = false;
      _picked.removeWhere((id) => !failures.containsKey(id));
    });
    if (failures.length == 1) {
      final entry = failures.entries.first;
      toast.error('${names[entry.key] ?? 'Not sent'}: ${entry.value}');
    } else {
      toast.error('Couldn\'t send to ${failures.length} people');
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull?.id;
    final rows = me == null
        ? const <ConversationModel>[]
        : ref.watch(conversationsProvider).valueOrNull ??
              const <ConversationModel>[];
    final profiles = ref.watch(profileCacheProvider);
    final candidates = me == null
        ? const <ConversationModel>[]
        : shareableConversations(rows, me);
    final people = [
      for (final c in candidates)
        if (profiles[c.otherParticipant(me!)] case final profile?)
          (conversationId: c.id, profile: profile),
    ];
    final names = {
      for (final p in people) p.conversationId: p.profile.displayName,
    };

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: NowaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: NowaColors.hairline)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: NowaColors.text.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (_browsing)
              _browse(people)
            else
              ..._overview(people.take(shareRecentLimit).toList(), me != null),
            if (_picked.isNotEmpty) _sendBar(names),
          ],
        ),
      ),
    );
  }

  List<Widget> _overview(List<_Person> recents, bool signedIn) {
    return [
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Text(
          _picked.isEmpty ? 'Share to' : 'Send to',
          style: sora(size: 15),
        ),
      ),
      if (recents.isNotEmpty) ...[
        const SizedBox(height: 14),
        SizedBox(
          key: const Key('share_recents'),
          height: 86,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: [
              for (final p in recents) ...[
                _PersonTile(
                  key: Key('share_recent_${p.conversationId}'),
                  name: p.profile.displayName,
                  avatarUrl: p.profile.avatarUrl,
                  picked: _picked.contains(p.conversationId),
                  onTap: _sending ? null : () => _toggle(p.conversationId),
                ),
                const SizedBox(width: 14),
              ],
            ],
          ),
        ),
        const Divider(color: NowaColors.hairline, height: 20),
      ] else
        const SizedBox(height: 16),
      SizedBox(
        height: 94,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          children: [
            // The app's own chats, not the phone's SMS app.
            _TargetTile(
              key: const Key('share_target_messages'),
              label: 'Messages',
              onTap: () => _openMessages(signedIn),
              tile: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: NowaColors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            for (final t in _targets) ...[
              _TargetTile(
                key: Key('share_target_${t.app.name}'),
                label: t.label,
                onTap: () => _shareTo(t.app),
                tile: _BrandTile(target: t),
              ),
              const SizedBox(width: 16),
            ],
            // Every other app on the phone, through the system sheet.
            _TargetTile(
              key: const Key('share_target_more'),
              label: 'More',
              onTap: _shareMore,
              tile: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: NowaColors.text.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  color: NowaColors.text,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
      if (_picked.isEmpty) ...[
        const SizedBox(height: 12),
        const Divider(color: NowaColors.hairline, height: 24),
        _Row(
          icon: Icons.link_rounded,
          label: 'Copy link',
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: _link));
            if (!mounted) return;
            NowaToast.of(context).success('Link copied');
            Navigator.of(context).pop(true);
          },
        ),
        _Row(
          icon: widget.saved
              ? Icons.bookmark_remove_outlined
              : Icons.bookmark_add_outlined,
          label: widget.saved ? 'Remove from favorites' : 'Add to favorites',
          onTap: widget.onToggleSave == null
              ? null
              : () {
                  Navigator.of(context).pop(false);
                  widget.onToggleSave!();
                },
        ),
        const _Row(icon: Icons.flag_outlined, label: 'Report', danger: true),
      ],
    ];
  }

  /// Every chat a video can go into, searchable by name.
  Widget _browse(List<_Person> people) {
    final query = _query.trim().toLowerCase();
    final shown = query.isEmpty
        ? people
        : people
              .where((p) => p.profile.displayName.toLowerCase().contains(query))
              .toList();
    final loading =
        ref.watch(conversationsProvider).isLoading && people.isEmpty;
    return SizedBox(
      key: const Key('share_conversations'),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 18, 4),
            child: Row(
              children: [
                IconButton(
                  key: const Key('share_conversations_back'),
                  tooltip: 'Back',
                  onPressed: () => setState(() {
                    _browsing = false;
                    _query = '';
                  }),
                  icon: const Icon(Icons.arrow_back, color: NowaColors.text),
                ),
                Text('Send to', style: sora(size: 15)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: TextField(
              key: const Key('share_conversations_search'),
              onChanged: (q) => setState(() => _query = q),
              style: work(size: 14),
              cursorColor: NowaColors.accent,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: NowaColors.text.withValues(alpha: 0.06),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: NowaColors.text.withValues(alpha: 0.5),
                ),
                hintText: 'Search',
                hintStyle: work(
                  size: 14,
                  color: NowaColors.text.withValues(alpha: 0.4),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: NowaColors.accent,
                      strokeWidth: 2,
                    ),
                  )
                : shown.isEmpty
                ? Center(
                    child: Text(
                      query.isEmpty ? 'No chats yet' : 'No one found',
                      style: work(size: 13, color: NowaColors.dim),
                    ),
                  )
                // Its own Material, so the rows' ink shows over the
                // sheet's colour.
                : Material(
                    type: MaterialType.transparency,
                    child: ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (_, i) {
                        final p = shown[i];
                        final picked = _picked.contains(p.conversationId);
                        return ListTile(
                          key: Key('share_conversation_${p.conversationId}'),
                          onTap: _sending
                              ? null
                              : () => _toggle(p.conversationId),
                          leading: NowaAvatar(
                            url: p.profile.avatarUrl,
                            size: 42,
                            radius: 21,
                            border: false,
                          ),
                          title: Text(
                            p.profile.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: work(size: 14),
                          ),
                          trailing: _Check(picked: picked),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// An optional note and Send, once someone is picked.
  Widget _sendBar(Map<String, String> names) {
    return Container(
      key: const Key('share_send_bar'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: NowaColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('share_note_field'),
              controller: _note,
              enabled: !_sending,
              maxLength: 300,
              minLines: 1,
              maxLines: 3,
              style: work(size: 14, height: 1.3),
              cursorColor: NowaColors.accent,
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                border: InputBorder.none,
                hintText: 'Add a message…',
                hintStyle: work(
                  size: 14,
                  color: NowaColors.text.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            key: const Key('share_send_button'),
            style: FilledButton.styleFrom(
              backgroundColor: NowaColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _sending ? null : () => _send(names),
            child: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _picked.length == 1 ? 'Send' : 'Send (${_picked.length})',
                    style: work(size: 13.5, weight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

typedef _Person = ({String conversationId, UserProfileModel profile});

/// Someone to send to: their avatar, ticked once picked, and their name.
class _PersonTile extends StatelessWidget {
  const _PersonTile({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.picked,
    required this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final bool picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 62,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                NowaAvatar(url: avatarUrl, size: 54, radius: 27, border: false),
                if (picked)
                  const Positioned(
                    right: -2,
                    bottom: -2,
                    child: _Check(picked: true),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              name,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: work(
                size: 11.5,
                color: NowaColors.text.withValues(alpha: picked ? 1 : 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.picked});

  final bool picked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: picked ? NowaColors.accent : Colors.transparent,
        border: Border.all(
          color: picked
              ? NowaColors.surface
              : NowaColors.text.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: picked
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : null,
    );
  }
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({
    super.key,
    required this.label,
    required this.onTap,
    required this.tile,
  });

  final String label;
  final VoidCallback onTap;
  final Widget tile;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          tile,
          const SizedBox(height: 8),
          SizedBox(
            width: 62,
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: work(
                size: 11.5,
                color: NowaColors.text.withValues(alpha: 0.62),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The app's own logo in white on its brand colour — how it looks on a home
/// screen, so it is recognised at a glance.
class _BrandTile extends StatelessWidget {
  const _BrandTile({required this.target});

  final _Target target;

  @override
  Widget build(BuildContext context) {
    final colors = target.colors;
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.length == 1 ? colors.first : null,
        gradient: colors.length > 1
            ? LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: colors,
              )
            : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SvgPicture.asset(
        target.logo,
        width: 28,
        height: 28,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? NowaColors.danger : NowaColors.text;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 14),
            Text(label, style: work(size: 14, color: color)),
            const Spacer(),
            if (onTap == null)
              Text(
                'not connected',
                style: work(
                  size: 11,
                  color: NowaColors.text.withValues(alpha: 0.28),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
