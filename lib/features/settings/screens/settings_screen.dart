import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../models/app_settings.dart';
import '../providers/settings_providers.dart';
import '../services/settings_controller.dart';
import '../widgets/danger_zone_card.dart';
import '../widgets/settings_dropdown_tile.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_switch_tile.dart';
import '../widgets/settings_tile.dart';

const String _appVersion = '0.1.0';
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

  void _showComingSoon(BuildContext context, String feature) {
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
          ? const Center(child: CircularProgressIndicator())
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsTile(
                    title: 'Export progress',
                    subtitle: 'Save your progress to a file',
                    leading: Icons.upload_outlined,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showComingSoon(context, 'Export progress'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsTile(
                    title: 'Import progress',
                    subtitle: 'Restore progress from a file',
                    leading: Icons.download_outlined,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showComingSoon(context, 'Import progress'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DangerZoneCard(
                    title: 'Reset progress',
                    description:
                        'Erases all lesson progress, review schedules, and achievements. This cannot be undone.',
                    actionLabel: 'Reset',
                    onPressed: () => _confirmAndRun(
                      context,
                      title: 'Reset progress?',
                      message:
                          'This permanently deletes all lesson progress, review schedules, and achievements.',
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Material(
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      children: [
                        AboutListTile(
                          icon: const Icon(Icons.info_outline),
                          applicationName: 'Japanese Learning',
                          applicationVersion:
                              '$_appVersion (build $_appBuildNumber)',
                          applicationLegalese:
                              '© ${DateTime.now().year} Japanese Learning',
                          aboutBoxChildren: const [
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'Built with Flutter, Riverpod, and Google Fonts.',
                            ),
                          ],
                          child: const Text('About'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }
}
