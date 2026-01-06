import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/video_provider.dart';
import '../../models/video_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/restaurant_provider.dart';
import '../../models/restaurant_model.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userDetailsAsync = ref.watch(userDetailsProvider);

    return userDetailsAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Business not found')),
          );
        }

        final videosAsync = ref.watch(userVideosProvider(user.uid));
        final restaurantAsync = ref.watch(currentBusinessProvider);

        return Scaffold(
          appBar: AppBar(
            title: Text(user.username),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit Restaurant tapped')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // Open settings/menu
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userDetailsProvider);
              ref.invalidate(currentBusinessProvider);
              ref.invalidate(userVideosProvider(user.uid));
              // Wait for user details to reload
              await ref.read(userDetailsProvider.future);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BusinessHeader(user: user),
                  const SizedBox(height: 24),
                  Text(
                    'Analytics Overview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  restaurantAsync.when(
                    data: (restaurant) => _AnalyticsGrid(
                      restaurant: restaurant,
                      videos: videosAsync.value ?? [],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading analytics: $e'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'My Videos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MyVideosGrid(videosAsync: videosAsync),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Orders',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _RecentOrdersList(),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _BusinessHeader extends StatelessWidget {
  final dynamic user;
  const _BusinessHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : const NetworkImage('https://via.placeholder.com/150'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                user.location.isNotEmpty ? user.location : 'Bahrain',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  final RestaurantModel? restaurant;
  final List<VideoModel> videos;

  const _AnalyticsGrid({this.restaurant, this.videos = const []});

  @override
  Widget build(BuildContext context) {
    // Sum total likes as a placeholder for "Total Views" or general engagement
    final totalLikes = videos.fold<int>(0, (sum, video) => sum + video.likes);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _AnalyticsCard(
          title: 'Total Likes',
          value: '$totalLikes',
          icon: Icons.favorite,
          color: Colors.red,
        ),
        _AnalyticsCard(
          title: 'Order Clicks',
          value: '${restaurant?.totalOrderClicks ?? 0}',
          icon: Icons.shopping_bag,
          color: Colors.green,
        ),
        _AnalyticsCard(
          title: 'Followers',
          value: '${restaurant?.followersCount ?? 0}',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _AnalyticsCard(
          title: 'Rating',
          value: '${restaurant?.rating ?? 0.0}',
          icon: Icons.star,
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        ],
      ),
    );
  }
}

class _RecentOrdersList extends StatelessWidget {
  const _RecentOrdersList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Order tracking coming soon',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            Text(
              'Manage your restaurant orders in real-time.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MyVideosGrid extends StatelessWidget {
  final AsyncValue<List<VideoModel>> videosAsync;
  const _MyVideosGrid({required this.videosAsync});

  @override
  Widget build(BuildContext context) {
    return videosAsync.when(
      data: (videos) {
        if (videos.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'No videos uploaded yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.7,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: video.thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: video.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                      ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
