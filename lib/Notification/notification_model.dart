class AppNotification {
  final String id;
  final String receiverId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String type; // live_start
  final String title;
  final String message;
  final int timestamp;
  final bool isRead;
  final String? streamId;

  AppNotification({
    required this.id,
    required this.receiverId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.streamId,
  });

  factory AppNotification.fromJson(String id, Map data) {
    return AppNotification(
      id: id,
      receiverId: data['receiverId'],
      senderId: data['senderId'],
      senderName: data['senderName'],
      senderAvatar: data['senderAvatar'],
      type: data['type'],
      title: data['title'],
      message: data['message'],
      timestamp: data['timestamp'],
      isRead: data['isRead'] ?? false,
      streamId: data['streamId'],
    );
  }
}
