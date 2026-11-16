import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../models/saving_entry.dart';

/// Line chart of a goal's saved balance over time (one point per day).
class GoalBalanceChart extends StatelessWidget {
  const GoalBalanceChart({
    super.key,
    required this.entries,
    required this.color,
  });

  /// Any order; sorted here.
  final List<SavingEntry> entries;
  final Color color;

  /// Running balance at the end of each day that has entries.
  static List<MapEntry<DateTime, double>> dailyBalance(
    List<SavingEntry> entries,
  ) {
    final sorted = [...entries]
      ..sort((a, b) {
        final c = a.entryDate.compareTo(b.entryDate);
        return c != 0
            ? c
            : (a.createdAt ?? a.entryDate).compareTo(
                b.createdAt ?? b.entryDate,
              );
      });
    final days = <DateTime, double>{};
    var running = 0.0;
    for (final e in sorted) {
      running += e.amount;
      days[DateTime(e.entryDate.year, e.entryDate.month, e.entryDate.day)] =
          running;
    }
    return days.entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final points = dailyBalance(entries);
    if (points.isEmpty) return const SizedBox.shrink();

    final first = points.first.key;
    final spots = [
      for (final p in points)
        FlSpot(p.key.difference(first).inDays.toDouble(), p.value),
    ];
    final single = spots.length == 1;
    final minX = single ? spots.first.x - 1 : 0.0;
    final maxX = single ? spots.first.x + 1 : spots.last.x;
    final maxY = math.max(1.0, spots.map((s) => s.y).reduce(math.max)) * 1.15;
    final interval = math.max(1.0, ((maxX - minX) / 3).ceilToDouble());
    final dateFmt = DateFormat('d MMM');
    final compact = NumberFormat.compact();
    final labelStyle = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance over time',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: Sp.lg),
            SizedBox(
              height: 180,
              child: LineChart(
                duration: const Duration(milliseconds: 250),
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: 0,
                  maxY: maxY,
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
                        getTitlesWidget: (v, meta) =>
                            v == meta.max || v == meta.min && v != 0
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
                        interval: interval,
                        getTitlesWidget: (v, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            dateFmt.format(
                              first.add(Duration(days: v.round())),
                            ),
                            style: labelStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) => [
                        for (final t in touched)
                          LineTooltipItem(
                            '${DateFormat('d MMM yyyy').format(first.add(Duration(days: t.x.round())))}\n${formatRm(t.y)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      preventCurveOverShooting: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: spots.length <= 12),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.12),
                      ),
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
