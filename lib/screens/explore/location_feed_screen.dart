import 'package:flutter/material.dart';
import '../../models/video_model.dart';
import '../../widgets/video/video_feed.dart';

class LocationFeedScreen extends StatelessWidget {
  final List<VideoModel> videos;
  final String title;
  final int initialIndex;

  const LocationFeedScreen({
    super.key,
    required this.videos,
    required this.title,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: videos.isEmpty
          ? const Center(
              child: Text(
                'No videos found in this area',
                style: TextStyle(color: Colors.white),
              ),
            )
          : VideoFeed(videos: videos, initialIndex: initialIndex),
    );
  }
}
