/// Static form options (not mock API data).
abstract final class AppOptions {
  static const applicationStages = [
    'Initial Application',
    'Shortlisted',
    'Interview Scheduled',
    'Offer Received',
    'Onboarding',
  ];

  static const fraudTypes = [
    'Registration Fee Scam',
    'Fake Offer Letter',
    'Data Harvesting',
    'No-Show Company',
    'Impersonation',
    'Unpaid Internship Trap',
  ];

  static const historyTypes = [
    'resume',
    'offer',
    'company',
    'blacklist',
  ];
}
