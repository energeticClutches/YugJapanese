import 'package:flutter/material.dart';

import '../../shared/widgets/app_scaffold.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Progress')),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Progress'),
            SizedBox(height: 12),
            Text('Coming Soon'),
          ],
        ),
      ),
    );
  }
}
