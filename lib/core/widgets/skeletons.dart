import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_theme.dart';

/// Shimmering placeholder rows shown while a list or card loads.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    this.shrink = false,
    this.padding = const EdgeInsets.all(Sp.md),
  });
  final int itemCount;

  /// Size to the content (for use inside another scroll view / dialog).
  final bool shrink;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Skeletonizer(
    child: ListView.separated(
      shrinkWrap: shrink,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: Sp.sm),
      itemBuilder: (_, _) => const Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          title: Text('Loading item title'),
          subtitle: Text('Category · due 12 Nov'),
          trailing: Text('RM 1,234.50'),
        ),
      ),
    ),
  );
}
