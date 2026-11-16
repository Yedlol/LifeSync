import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

String? validateEmail(String? v) {
  final s = v?.trim() ?? '';
  if (s.isEmpty) return 'Email is required';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Password is required';
  if (v.length < 6) return 'Password must be at least 6 characters';
  return null;
}

/// Centered layout shared by login and register.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    PhosphorIconsRegular.arrowsLeftRight,
                    size: 48,
                    color: kPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LifeSync',
                    textAlign: TextAlign.center,
                    style: text.headlineMedium?.copyWith(
                      color: kPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: text.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MessageBanner extends StatelessWidget {
  const MessageBanner(this.message, {super.key, this.isInfo = false});
  final String message;
  final bool isInfo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isInfo ? cs.primaryContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isInfo ? cs.onPrimaryContainer : cs.onErrorContainer,
        ),
      ),
    );
  }
}

class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 20,
    width: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
