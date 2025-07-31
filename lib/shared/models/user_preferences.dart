class UserPreferences {
  final List<UserGoal> goals;
  final Gender? gender;
  final DateTime? birthDate;
  
  UserPreferences({
    this.goals = const [],
    this.gender,
    this.birthDate,
  });
}

enum UserGoal {
  health('Health', '🏃'),
  confidence('Confidence', '💪'),
  energy('Energy', '⚡'),
  betterSleep('Better Sleep', '😴'),
  anxietyRelief('Anxiety Relief', '🧘'),
  emotionalBalance('Emotional Balance', '⚖️');
  
  final String title;
  final String emoji;
  
  const UserGoal(this.title, this.emoji);
}

enum Gender { male, female }