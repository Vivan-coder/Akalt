import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/video_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/restaurant_model.dart';
import '../../models/video_model.dart';
import '../../models/review_model.dart';

class BusinessDashboardScreen extends ConsumerWidget {
  final RestaurantModel restaurant;

  const BusinessDashboardScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsList = ref.watch(restaurantAnalyticsProvider(restaurant.id));
    final videosAsync = ref.watch(userVideosProvider(restaurant.id));
    // Since getReviews is a stream from service, we should probably add a provider for it or use FutureBuilder/StreamBuilder.
    // Ideally we add a provider in restaurant_provider.dart:
    // final restaurantReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, id) => ref.watch(restaurantServiceProvider).getReviews(id));
    // But for now, we'll access the service directly via the provider if needed, or better, assuming we can add the provider quickly.
    // Let's use the service directly for simplicity in this file, or standard StreamBuilder.
    final restaurantService = ref.watch(restaurantServiceProvider);

    final totalViews = analyticsList.fold<int>(0, (sum, item) => sum + item.views);
    final totalOrderClicks = analyticsList.fold<int>(0, (sum, item) => sum + item.clicks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Total Views',
                    value: '$totalViews',
                    icon: Icons.visibility,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    title: 'Order Clicks',
                    value: '$totalOrderClicks',
                    icon: Icons.touch_app,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MetricCard(
              title: 'Average Rating',
              value: restaurant.rating.toStringAsFixed(1),
              icon: Icons.star,
              color: Colors.amber,
            ),

            const SizedBox(height: 32),

            // Review Feed
            Text(
              'Recent Reviews',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: StreamBuilder<List<ReviewModel>>(
                stream: restaurantService.getReviews(restaurant.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final reviews = snapshot.data ?? [];
                  if (reviews.isEmpty) {
                    return const Center(child: Text('No reviews yet.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: review.userPhotoUrl != null
                              ? NetworkImage(review.userPhotoUrl!)
                              : null,
                          child: review.userPhotoUrl == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(review.username),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (starIndex) {
                                return Icon(
                                  starIndex < review.rating ? Icons.star : Icons.star_border,
                                  size: 14,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                            Text(review.text),
                          ],
                        ),
                        trailing: Text(
                          '${review.createdAt.day}/${review.createdAt.month}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Manage Menu
            Text(
              'Manage Menu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            videosAsync.when(
              data: (videos) {
                if (videos.isEmpty) return const Text('No videos uploaded.');
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            video.thumbnailUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey),
                          ),
                        ),
                        title: Text(video.dishName),
                        subtitle: Text('${video.price.toStringAsFixed(3)} BHD'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEditPriceDialog(context, ref, video);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading menu: $e'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPriceDialog(BuildContext context, WidgetRef ref, VideoModel video) {
    final controller = TextEditingController(text: video.price.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Price'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Price (BHD)',
            suffixText: 'BHD',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null) {
                // We need a method to update video price.
                // Assuming we can add updateVideoPrice to VideoService or just use generic update.
                // For now, let's assume we can call a method (which we might need to add to VideoService).
                // Or use Firestore directly here for speed if service method missing?
                // Better: Add updateVideoPrice to VideoService in next step if missing.
                // I will add the call here assuming it exists or I'll implement it.
                // Let's implement generic update in VideoService.
                await ref.read(videoServiceProvider).updateVideoPrice(video.id, newPrice);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
