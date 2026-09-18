class Achievement {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final bool Function(int totalMl, int streakDays, int logsToday) unlockCondition;

  const Achievement({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.unlockCondition,
  });

  static List<Achievement> all = [
    Achievement(
      id: 'first_sip',
      title: 'First Sip',
      emoji: '💧',
      description: 'Log your first drink',
      unlockCondition: (total, streak, today) => total > 0,
    ),
    Achievement(
      id: 'half_way',
      title: 'Halfway Hero',
      emoji: '🌊',
      description: 'Reach 50% of daily goal',
      unlockCondition: (_, __, ___) => false, // evaluated in provider with goal
    ),
    Achievement(
      id: 'goal_crusher',
      title: 'Goal Crusher',
      emoji: '🏆',
      description: 'Hit 100% of daily goal',
      unlockCondition: (_, __, ___) => false,
    ),
    Achievement(
      id: 'streak_3',
      title: '3-Day Splash',
      emoji: '🔥',
      description: '3 day streak',
      unlockCondition: (total, streak, today) => streak >= 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Hydration Legend',
      emoji: '👑',
      description: '7 day streak',
      unlockCondition: (total, streak, today) => streak >= 7,
    ),
    Achievement(
      id: 'big_chug',
      title: 'Big Chug',
      emoji: '🐳',
      description: 'Log 500ml+ in one tap',
      unlockCondition: (_, __, ___) => false,
    ),
  ];
}
