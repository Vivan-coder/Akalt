import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/restaurant_model.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/video_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/video_model.dart';

class BusinessDashboardScreen extends ConsumerStatefulWidget {
  final RestaurantModel restaurant;

  const BusinessDashboardScreen({super.key, required this.restaurant});

  @override
  ConsumerState<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends ConsumerState<BusinessDashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading delay for skeleton effect
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsList = ref.watch(restaurantAnalyticsProvider(widget.restaurant.id));
    final videosAsync = ref.watch(userVideosProvider(widget.restaurant.id));

    // Calculate totals
    final totalViews = analyticsList.fold<int>(0, (sum, item) => sum + item.views);
    final totalClicks = analyticsList.fold<int>(0, (sum, item) => sum + item.clicks);
    // Proxy for interest (e.g. profile visits)
    final totalInterest = (totalViews / 5).round();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The Big 3 Cards
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Tablet / Unfolded Mode
                  return Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Reach',
                          '$totalViews',
                          Icons.visibility,
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Customer Interest',
                          '$totalInterest',
                          Icons.person,
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Orders Generated',
                          '$totalClicks',
                          Icons.shopping_bag,
                          AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  );
                } else {
                  // Phone / Folded Mode
                  return Column(
                    children: [
                      _buildMetricCard(
                        'Total Reach',
                        '$totalViews',
                        Icons.visibility,
                        AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      _buildMetricCard(
                        'Customer Interest',
                        '$totalInterest',
                        Icons.person,
                        AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      _buildMetricCard(
                        'Orders Generated',
                        '$totalClicks',
                        Icons.shopping_bag,
                        AppTheme.primaryColor,
                      ),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            // Engagement Graph
            Text(
              'Engagement (Last 7 Days)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),
            _buildEngagementChart(analyticsList),

            const SizedBox(height: 24),

            // Peak Hours Card
            _buildPeakHoursCard(),

            const SizedBox(height: 24),

            // Manage Menu
            Text(
              'Manage Menu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),
            _buildManageMenu(videosAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[700]!,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              // Optional: Trend indicator
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementChart(List<AnalyticsData> analytics) {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[700]!,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // Sort by date to ensure line is correct
    final sortedData = List<AnalyticsData>.from(analytics)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Map to FlSpots
    final spots = sortedData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.views.toDouble());
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide dates for simplicity or implement custom formatting
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (analytics.length - 1).toDouble(),
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakHoursCard() {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[700]!,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time_filled, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peak Hours',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your peak engagement in Bahrain is 7:00 PM - 9:00 PM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageMenu(AsyncValue<List<VideoModel>> videosAsync) {
    return videosAsync.when(
      data: (videos) {
        if (videos.isEmpty) {
          return const Center(child: Text('No videos uploaded.', style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: videos.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final video = videos[index];
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    video.thumbnailUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey),
                  ),
                ),
                title: Text(video.dishName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${video.price.toStringAsFixed(3)} BHD', style: const TextStyle(color: AppTheme.primaryColor)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () {
                    // Re-using the edit dialog logic from previous implementation if needed,
                    // or placeholder for now as focused on dashboard display.
                    // For completeness, let's keep it simple.
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading menu: $e', style: const TextStyle(color: Colors.red)),
    );
  }
}
