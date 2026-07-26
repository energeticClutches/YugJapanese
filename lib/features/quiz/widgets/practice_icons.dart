import 'package:flutter/material.dart';

import '../models/practice_mode.dart';

IconData practiceModeIconForKey(String iconKey) {
  switch (iconKey) {
    case 'recognition':
      return Icons.visibility_outlined;
    case 'meaning':
      return Icons.translate_outlined;
    case 'reading':
      return Icons.menu_book_outlined;
    case 'listening':
      return Icons.headphones_outlined;
    case 'mixed':
      return Icons.shuffle;
    case 'weak_items':
      return Icons.trending_up;
    default:
      return Icons.quiz_outlined;
  }
}

String practiceDifficultyLabel(PracticeDifficulty difficulty) {
  switch (difficulty) {
    case PracticeDifficulty.beginner:
      return 'Beginner';
    case PracticeDifficulty.intermediate:
      return 'Intermediate';
    case PracticeDifficulty.advanced:
      return 'Advanced';
  }
}
