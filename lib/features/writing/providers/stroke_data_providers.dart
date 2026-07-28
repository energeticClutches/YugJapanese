import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stroke_template.dart';
import '../repositories/stroke_data_repository.dart';

final strokeDataRepositoryProvider = Provider<StrokeDataRepository>(
  (Ref ref) => StrokeDataRepository(),
);

/// Reference strokes for one character symbol, or `null` when the bundle
/// has no entry for it (the writing UI then falls back to free drawing).
final characterStrokesProvider =
    FutureProvider.family<CharacterStrokes?, String>((Ref ref, String symbol) {
      return ref.watch(strokeDataRepositoryProvider).strokesFor(symbol);
    });
