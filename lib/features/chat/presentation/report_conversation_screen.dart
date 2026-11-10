import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/data/chat_report_reasons.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

enum _Step { reason, select, done }

/// Report a conversation, the way the web client does: pick a reason, pick
/// the messages that show it (1–50), send, then be thanked — and offered a
/// block. Nothing is sent before Submit.
///
/// The messages to pick from are the ones the open thread has loaded. The
/// server reads who sent each one and what it said itself; the client names
/// only their ids.
class ReportConversationScreen extends ConsumerStatefulWidget {
  const ReportConversationScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    this.messageId,
  });

  final String conversationId;
  final String otherUserId;

  /// Set when the report starts from one message (its long-press menu): that
  /// message comes already picked, and nothing else does.
  final String? messageId;

  @override
  ConsumerState<ReportConversationScreen> createState() =>
      _ReportConversationScreenState();
}

class _ReportConversationScreenState
    extends ConsumerState<ReportConversationScreen> {
  _Step _step = _Step.reason;
  String? _reason;
  final _selected = <String>{};
  bool _preselected = false;
  bool _submitting = false;
  bool _blocked = false;
  bool _blocking = false;

  /// One per thing submitted: a resubmit of the same report after a lost
  /// response reuses it; changing the reason or the messages starts another.
  String _requestId = newClientRequestId();

  void _changed() => _requestId = newClientRequestId();

  void _toast(String message, [ToastKind kind = ToastKind.error]) {
    if (!mounted) return;
    NowaToast.of(context).show(message, kind: kind);
  }

  static bool _reportable(MessageModel m) => !m.pending && !m.recalled;

  /// A head start: the other person's latest few messages. Everything stays
  /// optional — the reporter decides what goes in.
  void _preselect(List<MessageModel> messages) {
    if (_preselected) return;
    _preselected = true;
    final start = widget.messageId;
    if (start != null && messages.any((m) => m.id == start && _reportable(m))) {
      _selected.add(start);
      return;
    }
    _selected.addAll(
      messages
          .where((m) => _reportable(m) && m.senderId == widget.otherUserId)
          .take(3)
          .map((m) => m.id),
    );
  }

  void _toggle(String id) {
    setState(() {
      _changed();
      if (!_selected.remove(id)) {
        if (_selected.length >= reportMaxMessages) {
          _toast(
            'You can select up to $reportMaxMessages messages',
            ToastKind.info,
          );
          return;
        }
        _selected.add(id);
      }
    });
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _selected.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .reportConversation(
            conversationId: widget.conversationId,
            reason: reason,
            messageIds: _selected.toList(),
            requestId: _requestId,
          );
      if (mounted) setState(() => _step = _Step.done);
    } on AppException catch (e) {
      _toast(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String _errorMessage(AppException e) {
    final code = e is ServerException ? e.code : null;
    return switch (code) {
      'REPORT_EVIDENCE_UNAVAILABLE' =>
        'Some selected messages can no longer be reported. Review your selection and try again.',
      'NOT_CONVERSATION_PARTICIPANT' ||
      'CONVERSATION_NOT_FOUND' => 'This conversation isn\'t available.',
      'CHAT_EVIDENCE_UNAVAILABLE' =>
        'We couldn\'t read the conversation right now. Try again in a moment.',
      'REPORT_ALREADY_SUBMITTED' =>
        'This report is already being sent. Try again in a moment.',
      _ => 'Couldn\'t send the report. Please try again.',
    };
  }

  Future<void> _block() async {
    if (_blocking || _blocked) return;
    setState(() => _blocking = true);
    try {
      await ref.read(userRepositoryProvider).block(widget.otherUserId);
      _blockedNow();
    } on ServerException catch (e) {
      if (e.code == 'ALREADY_BLOCKED') {
        _blockedNow();
      } else {
        _toast(e.message);
      }
    } on AppException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _blocking = false);
    }
  }

  void _blockedNow() {
    // Whether a thread can still be written to depends on the block.
    ref.invalidate(conversationsProvider);
    ref.invalidate(profileNotifierProvider(widget.otherUserId));
    if (mounted) setState(() => _blocked = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: NowaAppBar(
        title: switch (_step) {
          _Step.reason => 'Report',
          _Step.select => 'Select messages',
          _Step.done => 'Report sent',
        },
      ),
      body: switch (_step) {
        _Step.reason => _reasonStep(),
        _Step.select => _selectStep(),
        _Step.done => _doneStep(),
      },
    );
  }

  Widget _reasonStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Why are you reporting this conversation?',
            style: sora(size: 14),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final reason in chatReportReasons)
                ListTile(
                  key: Key('report_reason_$reason'),
                  dense: true,
                  title: Text(reason, style: work(size: 14)),
                  trailing: Icon(
                    _reason == reason
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: _reason == reason
                        ? NowaColors.accent
                        : NowaColors.text.withValues(alpha: 0.4),
                  ),
                  onTap: () => setState(() {
                    if (_reason != reason) _changed();
                    _reason = reason;
                  }),
                ),
            ],
          ),
        ),
        _bottomButton(
          key: const Key('report_next'),
          label: 'Next',
          onPressed: _reason == null
              ? null
              : () => setState(() => _step = _Step.select),
        ),
      ],
    );
  }

  Widget _selectStep() {
    final me = ref.watch(authStateProvider).valueOrNull?.id;
    final messages =
        (ref.watch(threadProvider(widget.conversationId)).valueOrNull ??
                const <MessageModel>[])
            .where((m) => !m.pending)
            .toList();
    _preselect(messages);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _reason ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: work(size: 12.5, color: NowaColors.dim),
                ),
              ),
              Text(
                '${_selected.length}/$reportMaxMessages selected',
                key: const Key('report_selected_count'),
                style: work(size: 12.5, color: NowaColors.dim),
              ),
            ],
          ),
        ),
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages to report',
                    style: work(size: 13, color: NowaColors.dim),
                  ),
                )
              : ListView.builder(
                  // Like the thread itself: newest at the bottom.
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final message = messages[i];
                    return _PickRow(
                      message: message,
                      mine: message.senderId == me,
                      selected: _selected.contains(message.id),
                      onTap: _reportable(message)
                          ? () => _toggle(message.id)
                          : null,
                    );
                  },
                ),
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _step = _Step.reason),
                child: Text('Back', style: work(size: 14)),
              ),
            ),
            Expanded(
              child: _bottomButton(
                key: const Key('report_submit'),
                label: _submitting ? 'Sending…' : 'Submit',
                onPressed: _selected.isEmpty || _submitting ? null : _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _doneStep() {
    final name =
        ref.watch(profileCacheProvider)[widget.otherUserId]?.displayName ??
        'this account';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const Icon(
            Icons.check_circle_outline,
            size: 56,
            color: NowaColors.accent,
          ),
          const SizedBox(height: 16),
          Text('Thanks for reporting', style: sora(size: 17)),
          const SizedBox(height: 8),
          Text(
            'We\'ll review the messages you selected. If they break our '
            'guidelines, we\'ll take action.',
            textAlign: TextAlign.center,
            style: work(size: 13.5, color: NowaColors.dim),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('report_block'),
              onPressed: _blocked || _blocking ? null : _block,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: NowaColors.hairline),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(
                _blocked ? 'Blocked' : 'Block $name',
                style: work(size: 14, color: NowaColors.danger),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('report_done'),
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: NowaColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(
                'Done',
                style: work(size: 14, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomButton({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: key,
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: NowaColors.accent,
              disabledBackgroundColor: NowaColors.surfaceHigh,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: Text(label, style: work(size: 14, weight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

/// One message in the picker. A recalled message carries nothing left to
/// report, so it is shown but cannot be ticked.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.message,
    required this.mine,
    required this.selected,
    required this.onTap,
  });

  final MessageModel message;
  final bool mine;
  final bool selected;
  final VoidCallback? onTap;

  String get _text {
    if (message.recalled) {
      return mine
          ? 'You unsent a message · can\'t be reported'
          : 'Message unsent · can\'t be reported';
    }
    if (message.type == MessageType.image) {
      return message.content.isEmpty ? 'Photo' : 'Photo · ${message.content}';
    }
    return message.content;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      key: Key('report_pick_${message.id}'),
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 22,
                color: selected
                    ? NowaColors.accent
                    : NowaColors.text.withValues(alpha: enabled ? 0.45 : 0.2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: mine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                        ),
                        decoration: BoxDecoration(
                          color: mine && !message.recalled
                              ? NowaColors.accent.withValues(alpha: 0.8)
                              : NowaColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _text,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: work(size: 13, height: 1.35),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeAgo(message.sentAt),
                        style: work(
                          size: 10,
                          height: 1,
                          color: NowaColors.text.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
