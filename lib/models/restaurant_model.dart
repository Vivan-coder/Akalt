class RestaurantModel {
  final String id;
  final String name;
  final String cuisine;
  final double rating;
  final String imageUrl;
  final String address;
  final double latitude;
  final double longitude;
  final double distance; // in km
  final String priceRange; // e.g., "$", "$$", "$$$"
  final List<String> tags;
  final int followersCount;
  final int totalOrderClicks;
  final String? orderLink; // URL to Talabat, Deliveroo, or direct ordering
  final String? orderPlatform; // 'talabat', 'deliveroo', 'direct', etc.

  RestaurantModel({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.imageUrl,
    required this.address,
    required this.distance,
    required this.latitude,
    required this.longitude,
    this.priceRange = "\$\$",
    this.tags = const [],
    this.followersCount = 0,
    this.totalOrderClicks = 0,
    this.orderLink,
    this.orderPlatform,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cuisine': cuisine,
      'rating': rating,
      'imageUrl': imageUrl,
      'address': address,
      'distance': distance,
      'latitude': latitude,
      'longitude': longitude,
      'priceRange': priceRange,
      'tags': tags,
      'followersCount': followersCount,
      'totalOrderClicks': totalOrderClicks,
      'orderLink': orderLink,
      'orderPlatform': orderPlatform,
    };
  }

  factory RestaurantModel.fromMap(Map<String, dynamic> map) {
    return RestaurantModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      cuisine: map['cuisine'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      address: map['address'] ?? '',
      distance: (map['distance'] ?? 0.0).toDouble(),
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      priceRange: map['priceRange'] ?? '\$\$',
      tags: List<String>.from(map['tags'] ?? []),
      followersCount: map['followersCount'] ?? 0,
      totalOrderClicks: map['totalOrderClicks'] ?? 0,
      orderLink: map['orderLink'],
      orderPlatform: map['orderPlatform'],
    );
  }
}
