import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../providers/overview_providers.dart';

const _billsColor = Color(0xFFF2A100);

/// Grouped bars: income vs bills paid, last 6 months.
class IncomeBillsChart extends StatelessWidget {
  const IncomeBillsChart({super.key, required this.points});
  final List<MonthPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxV = points.fold<double>(
      0,
      (m, p) => math.max(m, math.max(p.income, p.billsPaid)),
    );
    final maxY = maxV <= 0 ? 100.0 : maxV * 1.2;
    final compact = NumberFormat.compact();
    final month = DateFormat('MMM');
    final labelStyle = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);
    const tipStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );
    const topRound = BorderRadius.vertical(top: Radius.circular(4));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 6 months',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: Sp.sm),
            Row(
              children: [
                _Legend(color: scheme.primary, label: 'Income'),
                const SizedBox(width: Sp.lg),
                const _Legend(color: _billsColor, label: 'Bills paid'),
              ],
            ),
            const SizedBox(height: Sp.lg),
            SizedBox(
              height: 200,
              child: BarChart(
                duration: const Duration(milliseconds: 250),
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: scheme.outlineVariant, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, meta) => v == meta.max
                            ? const SizedBox.shrink()
                            : SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  compact.format(v),
                                  style: labelStyle,
                                ),
                              ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              month.format(points[i].month),
                              style: labelStyle,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem(
                        '${rodIndex == 0 ? 'Income' : 'Bills paid'}\n${formatRm(rod.toY)}',
                        tipStyle,
                      ),
                    ),
                  ),
                  barGroups: [
                    for (final (i, p) in points.indexed)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: p.income,
                            width: 10,
                            color: scheme.primary,
                            borderRadius: topRound,
                          ),
                          BarChartRodData(
                            toY: p.billsPaid,
                            width: 10,
                            color: _billsColor,
                            borderRadius: topRound,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
