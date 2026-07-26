import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Renders one of the project's root-level Markdown documents
/// (`PRIVACY_POLICY.md`, `TERMS_OF_USE.md`, `CREDITS.md`) inside the app.
///
/// The Markdown files are bundled as assets rather than duplicated into
/// Dart string literals so the in-app text and the repository copies can
/// never drift apart. No Markdown package is used (none is approved for
/// this project); [_MarkdownText] does a deliberately small subset of
/// formatting — headings, bullets, and bold — which is all these
/// documents contain.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text(title)),
      child: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const ErrorState(
              message: 'This document could not be loaded.',
            );
          }
          return SingleChildScrollView(
            child: _MarkdownText(source: snapshot.data!),
          );
        },
      ),
    );
  }
}

/// Minimal Markdown renderer covering only what the bundled legal
/// documents use: `#`/`##` headings, `-` bullets, `**bold**` runs, and
/// blank-line paragraph breaks. Anything else renders as plain text.
///
/// The source files are hard-wrapped at ~72 columns for readability in
/// the repository, so consecutive lines belonging to the same paragraph
/// or bullet are re-joined before layout — otherwise every source line
/// break would show up as a line break on screen and paragraphs would
/// wrap mid-sentence.
class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Widget> blocks = <Widget>[];

    // Accumulates the current paragraph or bullet across wrapped lines.
    final StringBuffer pending = StringBuffer();
    bool pendingIsBullet = false;

    void flushPending() {
      if (pending.isEmpty) {
        return;
      }
      final String text = pending.toString();
      pending.clear();
      if (pendingIsBullet) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: textTheme.bodyMedium),
                Expanded(child: _boldAwareText(text, textTheme, context)),
              ],
            ),
          ),
        );
      } else {
        blocks.add(_boldAwareText(text, textTheme, context));
      }
      pendingIsBullet = false;
    }

    for (final String rawLine in source.split('\n')) {
      final String line = rawLine.trim();

      if (line.isEmpty) {
        flushPending();
        blocks.add(const SizedBox(height: AppSpacing.md));
        continue;
      }

      if (line.startsWith('## ')) {
        flushPending();
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(line.substring(3), style: textTheme.titleMedium),
          ),
        );
        continue;
      }

      if (line.startsWith('# ')) {
        flushPending();
        blocks.add(Text(line.substring(2), style: textTheme.headlineSmall));
        continue;
      }

      if (line.startsWith('- ')) {
        // A new bullet ends whatever came before it.
        flushPending();
        pendingIsBullet = true;
        pending.write(line.substring(2));
        continue;
      }

      // Continuation of the current paragraph or bullet.
      if (pending.isNotEmpty) {
        pending.write(' ');
      }
      pending.write(line);
    }
    flushPending();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  /// Splits a line on `**` pairs so bold runs render bold and everything
  /// else renders normally.
  Widget _boldAwareText(
    String line,
    TextTheme textTheme,
    BuildContext context,
  ) {
    final List<String> parts = line.split('**');
    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium,
        children: <TextSpan>[
          for (int i = 0; i < parts.length; i++)
            TextSpan(
              text: parts[i],
              style: i.isOdd
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
        ],
      ),
    );
  }
}
