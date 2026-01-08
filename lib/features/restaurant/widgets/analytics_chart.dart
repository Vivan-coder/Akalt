import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/analytics_model.dart';
import '../../../../providers/restaurant_provider.dart';

class VideoPerformanceChart extends ConsumerWidget {
  const VideoPerformanceChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(restaurantAnalyticsProvider);

    return analyticsAsync.when(
      data: (data) => _ChartContent(data: data),
      loading: () => const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 300,
        child: Center(child: Text('Error loading chart: $e')),
      ),
    );
  }
}

class _ChartContent extends StatelessWidget {
  final List<DailyAnalytics> data;

  const _ChartContent({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text('No data available')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY() * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.grey[800]!,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayData = data[groupIndex];
                      final isViews = rodIndex == 0;
                      return BarTooltipItem(
                        '${DateFormat('MMM d').format(dayData.date)}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: isViews
                                ? 'Views: ${dayData.views}'
                                : 'Clicks: ${dayData.orderClicks}',
                            style: TextStyle(
                              color: isViews ? Colors.blue : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('E').format(data[value.toInt()].date),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final day = entry.value;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: day.views.toDouble(),
                        color: Colors.blue,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: day.orderClicks.toDouble(),
                        color: Colors.green,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _ChartLegend(),
        ],
      ),
    );
  }

  double _getMaxY() {
    double max = 0;
    for (var day in data) {
      if (day.views > max) max = day.views.toDouble();
      if (day.orderClicks > max) max = day.orderClicks.toDouble();
    }
    return max == 0 ? 100 : max;
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: Colors.blue, label: 'Views'),
        const SizedBox(width: 24),
        _LegendItem(color: Colors.green, label: 'Order Clicks'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
