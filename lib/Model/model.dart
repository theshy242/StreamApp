class StreamItem {
  final String name;
  final String category;
  final String url;
  final bool isLiveNow;
  final String colorHex;
  final String image;
  final String streamTitle;
  final String viewer;
  final String followers;
  final String coverImage;
  final String post;
  final String following;
  final String description;

  final String userId; // ⭐ trỏ tới User

  StreamItem({
    required this.name,
    required this.category,
    required this.url,
    required this.isLiveNow,
    required this.colorHex,
    required this.image,
    required this.streamTitle,
    required this.viewer,
    required this.followers,
    required this.coverImage,
    required this.post,
    required this.following,
    required this.description,
    required this.userId,
    // ⭐
  });

  factory StreamItem.fromJson(Map<String, dynamic> json) {
    return StreamItem(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      url: json['url'] ?? '',
      isLiveNow: json['isLiveNow'] ?? false,
      colorHex: json['colorHex'] ?? '',
      image: (json['image'] ?? json['imageUrl'])?.toString() ?? '',
      streamTitle: json['streamTitle'] ?? '',
      viewer: json['viewer'] ?? '',
      followers: json['followers'] ?? '',
      coverImage: json['coverImage'] ?? '',
      post: json['post'] ?? '',
      following: json['following'] ?? '',
      description: json['description'] ?? '',
      userId: json['userId'] ?? '',   // ⭐
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'url': url,
      'isLiveNow': isLiveNow,
      'colorHex': colorHex,
      'image': image,
      'streamTitle': streamTitle,
      'viewer': viewer,
      'followers': followers,
      'coverImage': coverImage,
      'post': post,
      'following': following,
      'description': description,
      'userId': userId,    // ⭐
    };
  }
}
