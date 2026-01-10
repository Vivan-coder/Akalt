import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/analytics_model.dart';
import '../../../../providers/restaurant_provider.dart';

class RestaurantPerformanceChart extends ConsumerWidget {
  const RestaurantPerformanceChart({super.key});

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

    return Column(
      children: [
        Container(
          height: 300,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxY() * 1.25,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF2C2C2E),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isViews = rodIndex == 0;
                    return BarTooltipItem(
                      '',
                      const TextStyle(),
                      children: [
                        TextSpan(
                          text: isViews ? 'Views: ' : 'Clicks: ',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text: rod.toY.toInt().toString(),
                          style: TextStyle(
                            color: isViews ? Colors.blue : Colors.greenAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          DateFormat('E').format(data[value.toInt()].date),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _getMaxY() / 4 > 0 ? _getMaxY() / 4 : 20,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                final idx = entry.key;
                final day = entry.value;
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: day.views.toDouble(),
                      color: Colors.blue,
                      width: 10,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                    BarChartRodData(
                      toY: day.orderClicks.toDouble(),
                      color: Colors.greenAccent,
                      width: 10,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
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
        const SizedBox(width: 32),
        _LegendItem(color: Colors.greenAccent, label: 'Order Clicks'),
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
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
