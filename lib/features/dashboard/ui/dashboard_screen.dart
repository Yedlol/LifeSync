import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Dashboard',
    icon: PhosphorIconsFill.squaresFour,
  );
}
