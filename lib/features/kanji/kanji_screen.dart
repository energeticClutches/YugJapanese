import 'package:flutter/material.dart';

import '../../shared/widgets/app_scaffold.dart';

class KanjiScreen extends StatelessWidget {
  const KanjiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Kanji')),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Kanji'),
            SizedBox(height: 12),
            Text('Coming Soon'),
          ],
        ),
      ),
    );
  }
}
