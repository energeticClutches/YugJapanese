import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/writing_evaluator.dart';

final writingEvaluatorProvider = Provider<WritingEvaluator>(
  (Ref ref) => const WritingEvaluator(),
);
