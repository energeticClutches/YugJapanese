import 'package:flutter/material.dart';

class RecentSearchChip extends StatelessWidget {
  const RecentSearchChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.history, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
