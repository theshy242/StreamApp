class VodModel {
  final String fileName;
  final String downloadUrl;
  final int size;
  final DateTime lastModified;

  VodModel({
    required this.fileName,
    required this.downloadUrl,
    required this.size,
    required this.lastModified,
  });

  factory VodModel.fromJson(Map<String, dynamic> json) {
    return VodModel(
      fileName: json['fileName'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      size: json['size'] ?? 0,
      lastModified: DateTime.parse(json['lastModified'] ?? DateTime.now().toString()),
    );
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1048576) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1048576).toStringAsFixed(1)} MB';
  }
}