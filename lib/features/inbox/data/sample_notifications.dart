/// Placeholder rows for the inbox.
///
/// There is no notification endpoint in the backend, so the screen renders
/// this fixed list to keep the design intact. Swap it for a provider the day
/// the service exists — [InboxNotification] already has the shape the row
/// widget expects.
class InboxNotification {
  const InboxNotification(this.who, this.what, this.when, this.badge, this.accent);

  final String who;
  final String what;
  final String when;
  final String badge;
  final bool accent;
}

const sampleNotifications = <InboxNotification>[
  InboxNotification(
    'Benri Studio',
    'replied to your comment: "he does this every night"',
    '2h',
    '♥',
    true,
  ),
  InboxNotification('thao.ng and 1.2K others', 'liked your video', '4h', '♥', true),
  InboxNotification('Long An Daily', 'started following you', '6h', '+', false),
  InboxNotification('Hà Noodles', 'mentioned you in a comment', '1d', '@', false),
  InboxNotification('Duc Builds', 'used your sound in a new video', '1d', '♪', false),
  InboxNotification('kurua', 'saved your video', '2d', '★', true),
];
