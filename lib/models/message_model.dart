import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final Timestamp timestamp;
  final bool isRead;
  final String mediaUrl;
  final bool isUploading;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.mediaUrl = '',
    this.isUploading = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp,
      'isRead': isRead,
      'mediaUrl': mediaUrl,
      'isUploading': isUploading,
    };
  }

  // Create from Firestore document
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    MessageType getType(String typeStr) {
      switch (typeStr) {
        case 'image':
          return MessageType.image;
        case 'video':
          return MessageType.video;
        case 'audio':
          return MessageType.audio;
        case 'file':
          return MessageType.file;
        default:
          return MessageType.text;
      }
    }

    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      type: getType(map['type'] ?? 'text'),
      timestamp: map['timestamp'] ?? Timestamp.now(),
      isRead: map['isRead'] ?? false,
      mediaUrl: map['mediaUrl'] ?? '',
      isUploading: map['isUploading'] ?? false,
    );
  }

  // Create a copy with updated fields
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    Timestamp? timestamp,
    bool? isRead,
    String? mediaUrl,
    bool? isUploading,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}
