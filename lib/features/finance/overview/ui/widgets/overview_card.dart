import 'package:flutter/material.dart';

import '../../../../../core/utils/money.dart';

/// One figure on the Overview tab; tappable when [onTap] is set.
class OverviewCard extends StatelessWidget {
  const OverviewCard({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    this.icon,
    this.caption,
    this.onTap,
    this.large = false,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData? icon;
  final String? caption;
  final VoidCallback? onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: large ? color.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: large ? color.withValues(alpha: 0.4) : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(large ? 20 : 16),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: text.labelLarge?.copyWith(
                        fontWeight: large ? FontWeight.w800 : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRm(amount),
                      style: (large ? text.headlineMedium : text.titleLarge)
                          ?.copyWith(fontWeight: FontWeight.w700, color: color),
                    ),
                    if (caption != null)
                      Text(
                        caption!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}
