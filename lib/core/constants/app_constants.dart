class AppConstants {
  AppConstants._();

  // College Email Domain
  static const String allowedEmailDomain = '@saveetha.com';
  static const String collegeName = 'Saveetha University';

  // App Info
  static const String appName = 'CampusConnect';
  static const String appTagline = 'Skills. Gigs. Campus.';

  // Gig Categories
  static const List<String> gigCategories = [
    'All',
    'Design',
    'Development',
    'Writing',
    'Marketing',
    'Video & Animation',
    'Photography',
    'Music & Audio',
    'Data & AI',
    'Tutoring',
    'Other',
  ];

  // Category Icons (Material Icons codepoints as string names)
  static const Map<String, String> categoryIcons = {
    'All': 'grid_view',
    'Design': 'palette',
    'Development': 'code',
    'Writing': 'edit_note',
    'Marketing': 'campaign',
    'Video & Animation': 'videocam',
    'Photography': 'camera_alt',
    'Music & Audio': 'music_note',
    'Data & AI': 'auto_graph',
    'Tutoring': 'school',
    'Other': 'more_horiz',
  };

  // Skill Tags
  static const List<String> popularSkills = [
    'UI/UX Design',
    'Flutter',
    'React',
    'Python',
    'Machine Learning',
    'Video Editing',
    'Photoshop',
    'Content Writing',
    'SEO',
    'Logo Design',
    'Web Development',
    'Android',
    'Data Analysis',
    'Illustration',
    'Photography',
    'Music Production',
    'Voice Over',
    'Translation',
    'Math Tutoring',
    '3D Modeling',
  ];

  // Gig Status
  static const String gigStatusOpen = 'open';
  static const String gigStatusInProgress = 'in-progress';
  static const String gigStatusCompleted = 'completed';
  static const String gigStatusCancelled = 'cancelled';

  // Bid Status
  static const String bidStatusPending = 'pending';
  static const String bidStatusAccepted = 'accepted';
  static const String bidStatusRejected = 'rejected';

  // Limits
  static const int maxPortfolioImages = 6;
  static const int maxGigAttachments = 3;
  static const double maxBudget = 50000;
  static const double minBudget = 50;
  static const int maxSkillsPerUser = 10;
}
