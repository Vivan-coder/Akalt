import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/video_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId; // If null, shows current user's profile

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleBookmark() {
    setState(() => _isBookmarked = !_isBookmarked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Bookmarked' : 'Bookmark removed'),
      ),
    );
  }

  void _editProfile() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit Profile tapped')));
  }

  @override
  Widget build(BuildContext context) {
    // Determine which user to display
    final currentUser = ref.watch(currentUserProvider);
    final targetUserId = widget.userId ?? currentUser?.uid;

    // If no target user, show error
    if (targetUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view profiles')),
      );
    }

    // Use different provider based on whether viewing self or others
    final bool isViewingSelf =
        widget.userId == null || widget.userId == currentUser?.uid;

    final userAsync = isViewingSelf
        ? ref.watch(userDetailsProvider)
        : ref.watch(userByIdProvider(targetUserId));

    return Scaffold(
      appBar: AppBar(
        title: userAsync.when(
          data: (user) => Text(
            user?.username ?? 'Profile',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Profile'),
        ),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.menu), onPressed: () {})],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }
          final userVideosAsync = ref.watch(userVideosProvider(user.uid));

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : const NetworkImage(
                                'https://via.placeholder.com/150',
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('Following', '${user.following.length}'),
                          _buildStat('Followers', '${user.followers.length}'),
                          userVideosAsync.when(
                            data: (videos) {
                              final totalLikes = videos.fold<int>(
                                0,
                                (sum, video) => sum + video.likes,
                              );
                              return _buildStat('Likes', '$totalLikes');
                            },
                            loading: () => _buildStat('Likes', '...'),
                            error: (_, __) => _buildStat('Likes', '0'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Show follow button if viewing another user's profile
                      if (!isViewingSelf) ...[
                        Consumer(
                          builder: (context, ref, _) {
                            final isFollowingAsync = ref.watch(
                              isFollowingProvider(user.uid),
                            );
                            final isFollowing = isFollowingAsync.value ?? false;

                            return ElevatedButton(
                              onPressed: () async {
                                final currentUser = ref.read(
                                  currentUserProvider,
                                );
                                if (currentUser != null) {
                                  await ref
                                      .read(userServiceProvider)
                                      .toggleFollow(currentUser.uid, user.uid);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? AppTheme.surfaceColor
                                    : AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(isFollowing ? 'Following' : 'Follow'),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Show edit profile button only when viewing self
                      if (isViewingSelf) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _editProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.surfaceColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                              ),
                              child: const Text('Edit Profile'),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                ),
                                onPressed: _toggleBookmark,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppTheme.primaryColor,
                      indicatorWeight: 2,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: 'Videos', icon: Icon(Icons.grid_on)),
                        Tab(text: 'Liked', icon: Icon(Icons.favorite_border)),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Videos Tab
                userVideosAsync.when(
                  data: (videos) {
                    if (videos.isEmpty) {
                      return const Center(
                        child: Text(
                          'No videos yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(2),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        return Container(
                          color: Colors.grey[300],
                          child: video.thumbnailUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: video.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Center(
                                        child: Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                      ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) =>
                      const Center(child: Text('Error loading videos')),
                ),
                // Liked Tab
                const Center(
                  child: Text(
                    'Liked videos coming soon',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading profile')),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppTheme.backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
