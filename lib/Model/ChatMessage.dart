import 'package:flutter/material.dart';

class ChatMessage {
  final String messageId;
  final String streamId; // ID của stream đang diễn ra
  final String userId;
  final String userName;
  final String userAvatar;
  final String message;
  final int timestamp;
  final MessageType type;
  final bool isModerator;
  final bool isStreamer;

  ChatMessage({
    required this.messageId,
    required this.streamId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.message,
    required this.timestamp,
    this.type = MessageType.text,
    this.isModerator = false,
    this.isStreamer = false,
  });

  // Factory constructor từ JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] ?? '',
      streamId: json['streamId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Ẩn danh',
      userAvatar: json['userAvatar'] ?? 'https://cdn-icons-png.flaticon.com/512/1144/1144760.png',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      type: _parseMessageType(json['type']),
      isModerator: json['isModerator'] ?? false,
      isStreamer: json['isStreamer'] ?? false,
    );
  }

  // Chuyển thành JSON để lưu lên Firebase
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'streamId': streamId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'message': message,
      'timestamp': timestamp,
      'type': type.toString().split('.').last,
      'isModerator': isModerator,
      'isStreamer': isStreamer,
      'createdAt': timestamp,
    };
  }

  // Parse MessageType từ string
  static MessageType _parseMessageType(String type) {
    switch (type) {
      case 'system':
        return MessageType.system;
      case 'donation':
        return MessageType.donation;
      case 'subscription':
        return MessageType.subscription;
      case 'gift':
        return MessageType.gift;
      default:
        return MessageType.text;
    }
  }

  // Get time formatted
  String get formattedTime {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Kiểm tra có phải là tin nhắn đặc biệt không
  bool get isSpecial => type != MessageType.text;
}

// Enum loại tin nhắn
enum MessageType {
  text,
  system,
  donation,
  subscription,
  gift,
}

// Extension để có màu sắc cho từng loại tin nhắn
extension MessageTypeExtension on MessageType {
  Color get color {
    switch (this) {
      case MessageType.system:
        return Colors.blueAccent;
      case MessageType.donation:
        return Colors.orangeAccent;
      case MessageType.subscription:
        return Colors.purpleAccent;
      case MessageType.gift:
        return Colors.greenAccent;
      default:
        return Colors.white;
    }
  }

  IconData get icon {
    switch (this) {
      case MessageType.system:
        return Icons.info_outline;
      case MessageType.donation:
        return Icons.attach_money;
      case MessageType.subscription:
        return Icons.star;
      case MessageType.gift:
        return Icons.card_giftcard;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  String get displayName {
    switch (this) {
      case MessageType.system:
        return 'Hệ thống';
      case MessageType.donation:
        return 'Donate';
      case MessageType.subscription:
        return 'Subscribe';
      case MessageType.gift:
        return 'Quà tặng';
      default:
        return 'Chat';
    }
  }
}