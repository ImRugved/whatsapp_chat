import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final List<String> participants;
  final Map<String, dynamic> lastMessage;
  final Timestamp createdAt;
  final Map<String, int> unreadCount;

  ChatRoomModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.createdAt,
    required this.unreadCount,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'createdAt': createdAt,
      'unreadCount': unreadCount,
    };
  }

  // Create from Firestore document
  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? {},
      createdAt: map['createdAt'] ?? Timestamp.now(),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  // Create a copy with updated fields
  ChatRoomModel copyWith({
    String? id,
    List<String>? participants,
    Map<String, dynamic>? lastMessage,
    Timestamp? createdAt,
    Map<String, int>? unreadCount,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
