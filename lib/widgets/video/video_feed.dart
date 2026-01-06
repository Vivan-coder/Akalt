import 'package:flutter/material.dart';
import '../../models/video_model.dart';
import 'video_player_widget.dart';

class VideoFeed extends StatefulWidget {
  final List<VideoModel> videos;

  final int initialIndex;

  const VideoFeed({super.key, required this.videos, this.initialIndex = 0});

  @override
  State<VideoFeed> createState() => _VideoFeedState();
}

class _VideoFeedState extends State<VideoFeed> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: widget.videos.length,
      itemBuilder: (context, index) {
        return VideoPlayerWidget(video: widget.videos[index]);
      },
    );
  }
}
