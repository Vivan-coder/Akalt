import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/restaurant_model.dart';
import '../../providers/video_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _tagsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedRestaurantId;
  bool _isUploading = false;
  File? _videoFile;

  @override
  void dispose() {
    _captionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _videoFile = File(video.path);
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Video selected')));
        }
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking video: $e')));
      }
    }
  }

  Future<void> _uploadVideo(List<RestaurantModel> restaurants) async {
    if (!_formKey.currentState!.validate()) return;
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video first')),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to post')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final userDetails = ref.read(userDetailsProvider).value;
      final restaurant = restaurants.firstWhere(
        (r) => r.id == _selectedRestaurantId,
      );
      final tags = _tagsController.text
          .split(' ')
          .where((tag) => tag.isNotEmpty)
          .toList();

      await ref
          .read(videoServiceProvider)
          .uploadVideo(
            videoFile: _videoFile!,
            userId: currentUser.uid,
            username: userDetails?.username ?? 'User',
            caption: _captionController.text,
            tags: tags,
            restaurantId: restaurant.id,
            restaurantName: restaurant.name,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          restaurantsAsync.when(
            data: (restaurants) => TextButton(
              onPressed: _isUploading ? null : () => _uploadVideo(restaurants),
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Picker Placeholder
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _videoFile != null
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _videoFile != null
                            ? Icons.check_circle
                            : Icons.video_library,
                        size: 48,
                        color: _videoFile != null
                            ? AppTheme.primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _videoFile != null ? 'Video Selected' : 'Select Video',
                        style: TextStyle(
                          color: _videoFile != null
                              ? AppTheme.primaryColor
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Caption
              TextFormField(
                controller: _captionController,
                decoration: const InputDecoration(
                  labelText: 'Caption',
                  hintText: 'Write something about this dish...',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a caption';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tags
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'e.g., #burger #spicy #dinner',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 16),

              // Restaurant Selector
              restaurantsAsync.when(
                data: (restaurants) {
                  if (restaurants.isEmpty) {
                    return const Text(
                      'No restaurants found. Please contact admin.',
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedRestaurantId,
                    decoration: const InputDecoration(
                      labelText: 'Tag Restaurant',
                      prefixIcon: Icon(Icons.store),
                    ),
                    items: restaurants.map((restaurant) {
                      return DropdownMenuItem(
                        value: restaurant.id,
                        child: Text(restaurant.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRestaurantId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a restaurant';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading restaurants: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
