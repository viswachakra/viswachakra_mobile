import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? legend;
  const ChartCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.child,
      this.legend});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 11.5, color: AppColors.text3, height: 1.4)),
            if (legend != null) ...[const SizedBox(height: 8), legend!],
            const SizedBox(height: 14),
            SizedBox(height: 190, child: child),
          ],
        ),
      ),
    );
  }
}

Widget _legendDot(Color c, String label) {
  return Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.text2)),
  ]);
}

class CashFlowChart extends StatelessWidget {
  final List<MonthPoint> points;
  const CashFlowChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    const indigo = Color(0xFFB4232E);
    const green = Color(0xFF10B981);
    final step = (points.length / 6).ceil().clamp(1, 99);
    return ChartCard(
      title: 'Cash flow by month',
      subtitle: 'Claims billed (red) vs payments received (green). They rarely line up — the insurer pays in bulk batches.',
      legend: Row(children: [
        _legendDot(indigo, 'Claims raised'),
        const SizedBox(width: 16),
        _legendDot(green, 'Payments received'),
      ]),
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) =>
                const FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                getTitlesWidget: (v, meta) => Text(inrShort(v),
                    style: const TextStyle(fontSize: 9, color: AppColors.text3)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: step.toDouble(),
                getTitlesWidget: (v, meta) {
                  final i = v.round();
                  if (i < 0 || i >= points.length || i % step != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(points[i].label,
                        style: const TextStyle(fontSize: 9, color: AppColors.text3)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            _line([for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].raised.toDouble())], indigo),
            _line([for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].received.toDouble())], green),
          ],
        ),
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
        spots: spots,
        color: color,
        barWidth: 2.5,
        isCurved: true,
        curveSmoothness: 0.25,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.10)),
      );
}

class SettlementChart extends StatelessWidget {
  final Map<String, int> dist;
  const SettlementChart({super.key, required this.dist});

  @override
  Widget build(BuildContext context) {
    final keys = dist.keys.toList();
    final colors = [
      const Color(0xFF93C5FD),
      const Color(0xFF6EE7B7),
      const Color(0xFFFCD34D),
      const Color(0xFFFB923C),
      const Color(0xFFEF4444),
    ];
    final maxY = (dist.values.isEmpty ? 0 : dist.values.reduce((a, b) => a > b ? a : b)).toDouble();
    return ChartCard(
      title: 'How long settled claims took',
      subtitle: 'Of the claims that were paid, how many fell into each time band (days).',
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 1 : maxY * 1.15,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) =>
                const FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, meta) => Text('${v.toInt()}',
                    style: const TextStyle(fontSize: 9, color: AppColors.text3)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= keys.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(keys[i],
                        style: const TextStyle(fontSize: 9, color: AppColors.text3)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < keys.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: dist[keys[i]]!.toDouble(),
                  color: colors[i % colors.length],
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ]),
          ],
        ),
      ),
    );
  }
}
