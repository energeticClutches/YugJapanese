import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/search_providers.dart';
import '../services/favorites_controller.dart';

/// A star toggle for favoriting any (script, itemId) pair. Reusable
/// anywhere a character can be favorited, not just search results.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.script,
    required this.itemId,
    required this.symbol,
  });

  final String script;
  final String itemId;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FavoritesController controller = ref.watch(favoritesProvider);
    final bool isFavorite = controller.isFavorite('$script:$itemId');

    return IconButton(
      icon: Icon(isFavorite ? Icons.star : Icons.star_border),
      color: isFavorite ? Colors.amber[700] : null,
      tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
      onPressed: () =>
          controller.toggle(script: script, itemId: itemId, symbol: symbol),
    );
  }
}
