/// One thing a comment can be reported for, and the rules it covers: the
/// reporter reads these back before submitting, the way the web's report
/// sheet does ("We don't allow the following").
class CommentReportReason {
  const CommentReportReason(this.label, this.bullets);

  final String label;
  final List<String> bullets;
}

/// What a viewer can report a comment for. Copied from the web client's
/// `COMMENT_REPORT_REASONS`, in the same order.
///
/// `reason` is free text server-side, so the label itself is what gets stored
/// and the moderation console groups reports by it — keep the labels identical
/// to the web's, or the same complaint lands in two groups.
const commentReportScenarios = <CommentReportReason>[
  CommentReportReason('Violence, abuse, and criminal exploitation', [
    'Threatening violence against a person, group, or animal',
    'Promoting or facilitating criminal activity, trafficking, or exploitation',
  ]),
  CommentReportReason('Hate and harassment', [
    'Insulting, degrading, or using obscene language against someone',
    'Harassment or bullying, including coordinated pile-ons',
    'Attacking a person or group based on race, ethnicity, religion, gender, '
        'sexual orientation, or disability',
  ]),
  CommentReportReason('Suicide and self-harm', [
    'Promoting or giving instructions for suicide or self-harm',
    'Encouraging hoaxes, games, or challenges that lead to self-harm',
  ]),
  CommentReportReason('Misinformation', [
    'False or misleading claims that could cause harm, such as fake medical '
        'advice or election misinformation',
    'Passing off manipulated media as real',
  ]),
  CommentReportReason('Frauds and scams', [
    'Phishing links, fake giveaways, or investment and crypto scams',
    'Anything trying to trick people out of money or account details',
  ]),
  CommentReportReason('Deceptive behavior and spam', [
    'Bulk or repetitive posting, fake engagement, or unsolicited promotion',
    'Impersonating another person or business',
  ]),
  CommentReportReason('Nudity and sexual content', [
    'Sexual solicitation or content meant to arouse',
    'Any sexual content involving a minor, which we remove and report to the '
        'authorities',
  ]),
  CommentReportReason('Regulated goods and activities', [
    'Selling or promoting drugs, weapons, counterfeit goods, or other '
        'regulated products',
    'Promoting gambling or other activity that breaks the law',
  ]),
  CommentReportReason('Sharing personal information', [
    'Posting someone else\'s address, phone number, or other private details',
    'Threatening to expose private information',
  ]),
  CommentReportReason('Counterfeits and intellectual property', [
    'Selling counterfeit goods or using someone else\'s trademark or brand '
        'identity',
    'Reposting copyrighted work without permission',
  ]),
];

/// The labels alone: what a report sends, and what an admin picks from as
/// the reason for removing a comment.
final commentReportReasons = [
  for (final reason in commentReportScenarios) reason.label,
];
