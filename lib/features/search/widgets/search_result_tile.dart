import 'package:flutter/material.dart';

import '../models/search_result.dart';
import 'favorite_button.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.result,
    required this.onTap,
    this.showFavorite = true,
  });

  final SearchResult result;
  final VoidCallback onTap;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        child: Text(result.symbol),
      ),
      title: Text(result.title),
      subtitle: Text(result.subtitle),
      trailing: showFavorite
          ? FavoriteButton(
              script: result.script,
              itemId: result.learningItem.id,
              symbol: result.symbol,
            )
          : null,
      onTap: onTap,
    );
  }
}
