import 'package:flutter/material.dart';

/// A settings row bound to a single-choice preference, rendered as a
/// dropdown of [T] values with a display label per option.
class SettingsDropdownTile<T> extends StatelessWidget {
  const SettingsDropdownTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final IconData? leading;
  final T value;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading == null ? null : Icon(leading),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        items: options
            .map(
              (T option) => DropdownMenuItem<T>(
                value: option,
                child: Text(labelBuilder(option)),
              ),
            )
            .toList(growable: false),
        onChanged: (T? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }
}
