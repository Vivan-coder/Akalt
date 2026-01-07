class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? photoUrl;
  final List<String> following;
  final List<String> followers;
  final List<String> favoriteTags;
  final List<String> watchHistory;
  final List<String> savedVideos;
  final List<String> likedVideos;
  final String location; // "lat,lng"
  final String role; // 'user' or 'business'

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.photoUrl,
    this.following = const [],
    this.followers = const [],
    this.favoriteTags = const [],
    this.watchHistory = const [],
    this.savedVideos = const [],
    this.likedVideos = const [],
    this.location = '',
    this.role = 'user',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'following': following,
      'followers': followers,
      'favoriteTags': favoriteTags,
      'watchHistory': watchHistory,
      'savedVideos': savedVideos,
      'likedVideos': likedVideos,
      'location': location,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      photoUrl: map['photoUrl'],
      following: List<String>.from(map['following'] ?? []),
      followers: List<String>.from(map['followers'] ?? []),
      favoriteTags: List<String>.from(map['favoriteTags'] ?? []),
      watchHistory: List<String>.from(map['watchHistory'] ?? []),
      savedVideos: List<String>.from(map['savedVideos'] ?? []),
      likedVideos: List<String>.from(map['likedVideos'] ?? []),
      location: map['location'] ?? '',
      role: map['role'] ?? 'user',
    );
  }
}
