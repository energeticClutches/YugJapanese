import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/app_settings.dart';
import '../providers/settings_providers.dart';
import '../services/settings_controller.dart';
import '../widgets/danger_zone_card.dart';
import '../widgets/settings_dropdown_tile.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_switch_tile.dart';
import '../widgets/settings_tile.dart';

/// Keep these in sync with `version:` in `pubspec.yaml`.
const String _appName = 'YugJapanese';
const String _appVersion = '1.0.0';
const String _appBuildNumber = '1';

String _themeModeLabel(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.system:
      return 'System';
    case AppThemeMode.light:
      return 'Light';
    case AppThemeMode.dark:
      return 'Dark';
  }
}

String _animationSpeedLabel(AnimationSpeed speed) {
  switch (speed) {
    case AnimationSpeed.slow:
      return 'Slow';
    case AnimationSpeed.normal:
      return 'Normal';
    case AnimationSpeed.fast:
      return 'Fast';
  }
}

String _writingHandLabel(WritingHand hand) {
  switch (hand) {
    case WritingHand.left:
      return 'Left-handed';
    case WritingHand.right:
      return 'Right-handed';
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await action();

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  /// Shows the "not built yet" notice, but at most once per 15 minutes per
  /// feature. Without this, mashing Export/Import queued a SnackBar per
  /// tap — `ScaffoldMessenger` queues rather than dedupes, so rapid taps
  /// played the whole backlog back one after another.
  void _showComingSoon(BuildContext context, WidgetRef ref, String feature) {
    if (!ref.read(comingSoonGateProvider).shouldShow(feature)) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is not available yet.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsController controller = ref.watch(currentSettingsProvider);
    final AppSettings settings = controller.settings;

    return AppScaffold(
      appBar: AppBar(title: const Text('Settings')),
      child: !controller.isReady
          ? const LoadingIndicator()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsSection(
                    title: 'Appearance',
                    children: [
                      SettingsDropdownTile<AppThemeMode>(
                        title: 'Theme',
                        leading: Icons.brightness_6_outlined,
                        value: settings.themeMode,
                        options: AppThemeMode.values,
                        labelBuilder: _themeModeLabel,
                        onChanged: (AppThemeMode mode) =>
                            controller.update(settings.copyWith(themeMode: mode)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SettingsSection(
                    title: 'Learning',
                    children: [
                      SettingsSwitchTile(
                        title: 'Show stroke guides',
                        subtitle: 'Display stroke order hints while writing',
                        leading: Icons.gesture_outlined,
                        value: settings.showStrokeGuide,
                        onChanged: (bool value) => controller
                            .update(settings.copyWith(showStrokeGuide: value)),
                      ),
                      SettingsSwitchTile(
                        title: 'Show writing grid',
                        subtitle: 'Display a reference grid on the canvas',
                        leading: Icons.grid_4x4_outlined,
                        value: settings.showGrid,
                        onChanged: (bool value) =>
                            controller.update(settings.copyWith(showGrid: value)),
                      ),
                      SettingsDropdownTile<AnimationSpeed>(
                        title: 'Animation speed',
                        leading: Icons.speed_outlined,
                        value: settings.animationSpeed,
                        options: AnimationSpeed.values,
                        labelBuilder: _animationSpeedLabel,
                        onChanged: (AnimationSpeed speed) => controller
                            .update(settings.copyWith(animationSpeed: speed)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SettingsSection(
                    title: 'Feedback',
                    children: [
                      SettingsSwitchTile(
                        title: 'Sound effects',
                        leading: Icons.volume_up_outlined,
                        value: settings.soundEnabled,
                        onChanged: (bool value) => controller
                            .update(settings.copyWith(soundEnabled: value)),
                      ),
                      SettingsSwitchTile(
                        title: 'Haptic feedback',
                        leading: Icons.vibration_outlined,
                        value: settings.hapticsEnabled,
                        onChanged: (bool value) => controller
                            .update(settings.copyWith(hapticsEnabled: value)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SettingsSection(
                    title: 'Accessibility',
                    children: [
                      SettingsSwitchTile(
                        title: 'Larger writing area',
                        subtitle: 'Coming soon',
                        leading: Icons.zoom_out_map_outlined,
                        value: settings.largerWritingArea,
                        onChanged: (bool value) => controller.update(
                          settings.copyWith(largerWritingArea: value),
                        ),
                      ),
                      SettingsDropdownTile<WritingHand>(
                        title: 'Writing hand',
                        leading: Icons.back_hand_outlined,
                        value: settings.preferredWritingHand,
                        options: WritingHand.values,
                        labelBuilder: _writingHandLabel,
                        onChanged: (WritingHand hand) => controller.update(
                          settings.copyWith(preferredWritingHand: hand),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Data Management',
                    // titleLarge to match the section-heading size used
                    // by SettingsSection above and every other screen's
                    // section headers (Milestone 21, Issue 3).
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsTile(
                    title: 'Export progress',
                    subtitle: 'Save your progress to a file',
                    leading: Icons.upload_outlined,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showComingSoon(context, ref, 'Export progress'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsTile(
                    title: 'Import progress',
                    subtitle: 'Restore progress from a file',
                    leading: Icons.download_outlined,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showComingSoon(context, ref, 'Import progress'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DangerZoneCard(
                    title: 'Reset progress',
                    description:
                        'Erases all lesson progress, review schedules, achievements, practice history, and analytics. This cannot be undone.',
                    actionLabel: 'Reset',
                    onPressed: () => _confirmAndRun(
                      context,
                      title: 'Reset progress?',
                      message:
                          'This permanently deletes all lesson progress, review schedules, achievements, practice history, and analytics.',
                      confirmLabel: 'Reset',
                      action: controller.resetAllProgress,
                      successMessage: 'Progress has been reset.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DangerZoneCard(
                    title: 'Reset settings',
                    description:
                        'Restores all preferences on this screen to their defaults.',
                    actionLabel: 'Reset',
                    onPressed: () => _confirmAndRun(
                      context,
                      title: 'Reset settings?',
                      message:
                          'This restores theme, learning, feedback, and accessibility preferences to their defaults.',
                      confirmLabel: 'Reset',
                      action: controller.resetSettings,
                      successMessage: 'Settings have been reset.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'About',
                    // titleLarge to match the section-heading size used
                    // by SettingsSection above and every other screen's
                    // section headers (Milestone 21, Issue 3).
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Material(
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      children: [
                        AboutListTile(
                          icon: const Icon(Icons.info_outline),
                          applicationName: _appName,
                          applicationVersion:
                              '$_appVersion (build $_appBuildNumber)',
                          applicationLegalese:
                              '© ${DateTime.now().year} energeticClutches. '
                              'Released under the MIT License.',
                          aboutBoxChildren: const [
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'An offline-first Japanese learning app for '
                              'Hiragana, Katakana, and Kanji.\n\n'
                              'Built with Flutter, Riverpod, Hive, and '
                              'Noto Sans JP via Google Fonts. See Credits & '
                              'Attribution for the full list.',
                            ),
                          ],
                          child: const Text('About'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Legal',
                    // titleLarge to match the section-heading size used
                    // by SettingsSection above and every other screen's
                    // section headers (Milestone 21, Issue 3).
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsTile(
                    title: 'Privacy Policy',
                    subtitle: 'How your data is handled (spoiler: it stays here)',
                    leading: Icons.privacy_tip_outlined,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/legal/privacy'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsTile(
                    title: 'Terms of Use',
                    subtitle: 'Usage terms and license',
                    leading: Icons.gavel_outlined,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/legal/terms'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsTile(
                    title: 'Credits & Attribution',
                    subtitle: 'Open-source software and assets used',
                    leading: Icons.favorite_outline,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/legal/credits'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Diagnostics',
                    // titleLarge to match the section-heading size used
                    // by SettingsSection above and every other screen's
                    // section headers (Milestone 21, Issue 3).
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Consumer(
                    builder: (BuildContext context, WidgetRef ref, _) {
                      final AsyncValue<int> storageAsync =
                          ref.watch(storageUsageProvider);
                      return SettingsTile(
                        title: 'Storage usage',
                        subtitle: storageAsync.when(
                          data: (int bytes) => _formatBytes(bytes),
                          loading: () => 'Calculating…',
                          error: (Object error, StackTrace stackTrace) =>
                              'Unavailable',
                        ),
                        leading: Icons.storage_outlined,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsTile(
                    title: 'Licenses',
                    subtitle: 'Open-source software used in this app',
                    leading: Icons.description_outlined,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: _appName,
                      applicationVersion: '$_appVersion (build $_appBuildNumber)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final double kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final double mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}
