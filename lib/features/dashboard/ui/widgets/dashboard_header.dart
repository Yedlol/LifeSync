import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';

String greetingFor(DateTime now) => now.hour < 12
    ? 'Good morning'
    : now.hour < 18
    ? 'Good afternoon'
    : 'Good evening';

/// "Good morning" + "Tuesday, 17 Nov 2026".
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greetingFor(now),
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Sp.xs),
        Text(
          DateFormat('EEEE, d MMM yyyy').format(now),
          style: text.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
