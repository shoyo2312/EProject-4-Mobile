/// What a viewer can report a comment for, and what an admin picks as the
/// reason for removing one.
///
/// `reason` is free text server-side, so the label itself is what gets stored
/// and the moderation console groups reports by it. These are the exact labels
/// the web client sends — keep them identical, or the same complaint lands in
/// two groups.
const commentReportReasons = <String>[
  'Violence, abuse, and criminal exploitation',
  'Hate and harassment',
  'Suicide and self-harm',
  'Misinformation',
  'Frauds and scams',
  'Deceptive behavior and spam',
];
