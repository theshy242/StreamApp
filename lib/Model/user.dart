class User {
  final String userId;
  final String name;
  final String email;
  final String avatar;
  final String serverUrl; // URL Nginx / RTMP / HLS của user
  final String description;
  final int followers;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.avatar,
    required this.serverUrl,
    required this.description,
    required this.followers,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['userId'] ?? '';
    return User(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      serverUrl: json['serverUrl'] ?? "rtmp://192.168.2.117/live/$id",
      description: json['description'] ?? '',
      followers: json['followers'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'avatar': avatar,
      'serverUrl': serverUrl,
      'description': description,
      'followers': followers,
    };
  }
}
