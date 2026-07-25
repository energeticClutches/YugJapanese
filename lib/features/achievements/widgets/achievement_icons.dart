import 'package:flutter/material.dart';

IconData achievementIconForKey(String iconKey) {
  switch (iconKey) {
    case 'flag':
      return Icons.flag_outlined;
    case 'stars':
      return Icons.stars_outlined;
    case 'streak':
      return Icons.local_fire_department_outlined;
    case 'review':
      return Icons.refresh;
    case 'target':
      return Icons.gps_fixed;
    default:
      return Icons.emoji_events_outlined;
  }
}
