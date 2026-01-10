class VideoModel {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String restaurantId;
  final String restaurantName;
  final String dishName;
  final String userId;
  final String username;
  final int likes;
  final int comments;
  final int shares;
  final int orderClicks;
  final int views;
  final double avgWatchTime;
  final List<String> tags;
  final String location; // "lat,lng" for legacy support
  final double? latitude;
  final double? longitude;
  final String? geohash;
  final DateTime createdAt;
  final double feedScore;
  final int saves;
  final double price;

  VideoModel({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.restaurantId,
    required this.restaurantName,
    required this.dishName,
    required this.userId,
    required this.username,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.orderClicks = 0,
    this.views = 0,
    this.avgWatchTime = 0.0,
    this.tags = const [],
    this.location = '',
    this.latitude,
    this.longitude,
    this.geohash,
    required this.createdAt,
    this.feedScore = 0.0,
    this.saves = 0,
    this.price = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'dishName': dishName,
      'userId': userId,
      'username': username,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'orderClicks': orderClicks,
      'views': views,
      'avgWatchTime': avgWatchTime,
      'tags': tags,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'createdAt': createdAt.toIso8601String(),
      'feedScore': feedScore,
      'saves': saves,
      'price': price,
    };
  }

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['id'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'] ?? '',
      dishName: map['dishName'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      shares: map['shares'] ?? 0,
      orderClicks: map['orderClicks'] ?? 0,
      views: map['views'] ?? 0,
      avgWatchTime: (map['avgWatchTime'] ?? 0.0).toDouble(),
      tags: List<String>.from(map['tags'] ?? []),
      location: map['location'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      geohash: map['geohash'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      feedScore: (map['feedScore'] ?? 0.0).toDouble(),
      saves: map['saves'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }
}
