/// What a conversation can be reported for. admin-service accepts exactly
/// these labels (DirectMessageReports.REASONS) and groups reports by them, so
/// they are sent verbatim and must stay identical to the web client's
/// `CHAT_REPORT_REASONS`.
const chatReportReasons = <String>[
  'Nudity and sexual content',
  'Sextortion and intimate image abuse',
  'Regulated goods and activities',
  'Hate and harassment',
  'Frauds and scams',
  'Minor safety',
  'Misinformation',
  'Violence, abuse, and criminal exploitation',
  'Suicide and self-harm',
  'Disordered eating and unhealthy body image',
  'Shocking and graphic content',
  'Dangerous activities and challenges',
  'Deceptive behavior and spam',
  'Sharing personal information',
  'Dangerous goods or services',
  'Intellectual property infringement',
  'Advertisement does not match the item',
  'Other',
];

/// The most messages one report may name.
const reportMaxMessages = 50;
