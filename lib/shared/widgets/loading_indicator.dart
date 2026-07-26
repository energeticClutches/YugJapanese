import 'package:flutter/material.dart';

/// Centered loading spinner, matching the sizing/style every screen was
/// previously reinventing ad hoc via a bare `CircularProgressIndicator()`.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
