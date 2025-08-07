import 'package:flutter/material.dart';

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
  health('Health', Icons.favorite_outline, Color(0xFFFF6B6B)),
  confidence('Confidence', Icons.psychology_outlined, Color(0xFF4ECDC4)),
  energy('Energy', Icons.bolt, Color(0xFFFFD93D)),
  betterSleep('Better Sleep', Icons.bedtime_outlined, Color(0xFF6C5CE7)),
  anxietyRelief('Anxiety Relief', Icons.self_improvement, Color(0xFF74B9FF)),
  emotionalBalance('Emotional Balance', Icons.balance, Color(0xFFA29BFE));
  
  final String title;
  final IconData icon;
  final Color color;
  
  const UserGoal(this.title, this.icon, this.color);
}

enum Gender { male, female }