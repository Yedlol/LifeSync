import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
      title: 'Finance', icon: Icons.account_balance_wallet);
}
