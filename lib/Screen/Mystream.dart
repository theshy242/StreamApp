class MyStream {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final bool isLive;

  MyStream({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.isLive,
  });

  // Chuyển object thành Map để push lên Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'imageUrl': imageUrl,
      'isLive': isLive,
    };
  }

  // Tạo object từ Map lấy về từ Firebase
  factory MyStream.fromJson(Map<String, dynamic> json) {
    return MyStream(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      isLive: json['isLive'] == true,
    );
  }
}
