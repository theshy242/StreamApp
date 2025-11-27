
class StreamCategory {
  final String title;

  StreamCategory({required this.title});

  factory StreamCategory.fromJson(Map<String, dynamic> json) {
    return StreamCategory(
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
    };
  }
}
