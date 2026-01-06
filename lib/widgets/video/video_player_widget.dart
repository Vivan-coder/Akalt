import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../models/video_model.dart';
import '../../theme/app_theme.dart';
import '../../models/restaurant_model.dart';
import '../../screens/profile/restaurant_profile_screen.dart';
import '../../providers/video_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'comments_sheet.dart';
import '../../providers/restaurant_provider.dart';

// Provider to check if a video is liked by the current user
final isLikedProvider = StreamProvider.family<bool, String>((ref, videoId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(false);
  return ref.watch(videoServiceProvider).isLiked(videoId, user.uid);
});

class VideoPlayerWidget extends ConsumerStatefulWidget {
  final VideoModel video;

  const VideoPlayerWidget({super.key, required this.video});

  @override
  ConsumerState<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends ConsumerState<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
          ..initialize()
              .then((_) {
                if (mounted) {
                  setState(() {
                    _isInitialized = true;
                  });
                  _controller.play();
                  _controller.setLooping(true);
                }
              })
              .catchError((error) {
                debugPrint('Video initialization error: $error');
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _errorMessage = error.toString();
                  });
                }
              });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLike() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to like videos')),
      );
      return;
    }
    try {
      await ref
          .read(videoServiceProvider)
          .toggleLike(widget.video.id, user.uid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleOrder() async {
    try {
      // Fetch restaurant data to get order link
      final restaurantsAsync = ref.read(restaurantsProvider);
      await restaurantsAsync.when(
        data: (restaurants) async {
          final restaurant = restaurants.firstWhere(
            (r) => r.id == widget.video.restaurantId,
            orElse: () => restaurants.first,
          );

          if (restaurant.orderLink != null &&
              restaurant.orderLink!.isNotEmpty) {
            final url = Uri.parse(restaurant.orderLink!);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
              // Track order click
              await ref
                  .read(videoServiceProvider)
                  .incrementOrderClicks(
                    widget.video.id,
                    widget.video.restaurantId,
                  );
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open ordering link')),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Ordering not available for ${restaurant.name} yet',
                  ),
                ),
              );
            }
          }
        },
        loading: () {},
        error: (_, __) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error loading restaurant data')),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLikedAsync = ref.watch(isLikedProvider(widget.video.id));
    final isLiked = isLikedAsync.value ?? false;

    return Stack(
      children: [
        // Video Player
        GestureDetector(
          onTap: () {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          },
          child: Container(
            color: Colors.black,
            child: Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : _hasError
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'Video Error',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _errorMessage ?? 'Unknown error',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),

        // Gradient Overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.6, 0.8, 1.0],
              ),
            ),
          ),
        ),

        // Right Side Actions (Premium Look)
        Positioned(
          right: 16,
          bottom: 120, // Raised slightly to clear bottom nav
          child: Column(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                  'https://via.placeholder.com/150',
                ),
                backgroundColor: AppTheme.surfaceColor,
              ),
              const SizedBox(height: 24),
              _buildAction(
                context,
                isLiked ? Icons.favorite : Icons.favorite_border,
                '${widget.video.likes}',
                color: isLiked ? Colors.red : Colors.white,
                onTap: _handleLike,
              ),
              const SizedBox(height: 20),
              _buildAction(
                context,
                Icons.comment_rounded,
                '${widget.video.comments}',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        CommentsSheet(videoId: widget.video.id),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildAction(
                context,
                Icons.share_rounded,
                'Share',
                onTap: () {
                  Share.share(
                    'Check out this delicious food! https://akalt.app/video/${widget.video.id}',
                  );
                  ref
                      .read(videoServiceProvider)
                      .incrementShareCount(widget.video.id);
                },
              ),
              const SizedBox(height: 20),
              // Order Button (New)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                  ),
                  onPressed: _handleOrder,
                ),
              ),
            ],
          ),
        ),

        // Bottom Info
        Positioned(
          left: 16,
          bottom: 100, // Raised to clear bottom nav
          right: 80,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantProfileScreen(
                    restaurant: RestaurantModel(
                      id: widget.video.restaurantId,
                      name: widget.video.restaurantName,
                      cuisine: 'Cuisine', // Placeholder
                      rating: 4.5, // Placeholder
                      imageUrl:
                          'https://via.placeholder.com/150', // Placeholder
                      address: 'Address', // Placeholder
                      distance: 1.2, // Placeholder
                      latitude: 0,
                      longitude: 0,
                      followersCount: 0,
                      totalOrderClicks: 0,
                    ),
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.video.restaurantName,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.verified,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.video.dishName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'BD 4.500', // Placeholder price
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAction(
    BuildContext context,
    IconData icon,
    String label, {
    Color color = Colors.white,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
