import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Rx<List<ChatRoomModel>> _chatRooms = Rx<List<ChatRoomModel>>([]);
  List<ChatRoomModel> get chatRooms => _chatRooms.value;

  final Rx<List<MessageModel>> _messages = Rx<List<MessageModel>>([]);
  List<MessageModel> get messages => _messages.value;

  final Rx<List<UserModel>> _contacts = Rx<List<UserModel>>([]);
  List<UserModel> get contacts => _contacts.value;

  // Map to track uploading images - messageId: local file path
  final RxMap<String, String> uploadingImages = RxMap<String, String>();

  final TextEditingController messageController = TextEditingController();
  final RxBool isEmojiVisible = false.obs;

  @override
  void onInit() {
    super.onInit();

    if (_auth.currentUser != null) {
      _getChatRooms();
      _getContacts();
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }

  // Get all chat rooms for current user
  void _getChatRooms() {
    _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: _auth.currentUser!.uid)
        .orderBy('lastMessage.timestamp', descending: true)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      List<ChatRoomModel> rooms = [];
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        // Debug print to check lastMessage data
        if (data.containsKey('lastMessage') && data['lastMessage'] is Map) {
          print('Chat room: ${doc.id}, lastMessage: ${data['lastMessage']}');
        }
        rooms.add(ChatRoomModel.fromMap(data));
      }
      _chatRooms.value = rooms;
    });
  }

  // Public method to refresh chat rooms
  void refreshChatRooms() {
    if (_auth.currentUser != null) {
      _getChatRooms();
    }
  }

  // Get all contacts (all users in the app for now)
  void _getContacts() {
    _firestore
        .collection('users')
        .where('uid', isNotEqualTo: _auth.currentUser!.uid)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      List<UserModel> users = [];
      for (var doc in snapshot.docs) {
        users.add(UserModel.fromMap(doc.data() as Map<String, dynamic>));
      }
      _contacts.value = users;
    });
  }

  // Get messages for a specific chat room
  void getMessages(String chatRoomId) {
    _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      List<MessageModel> msgs = [];
      for (var doc in snapshot.docs) {
        msgs.add(MessageModel.fromMap(doc.data() as Map<String, dynamic>));
      }
      _messages.value = msgs;
    });

    // Mark messages as read
    markMessagesAsRead(chatRoomId);
  }

  // Create or get existing chat room with another user
  Future<String> createOrGetChatRoom(String otherUserId) async {
    try {
      // Check if chat room already exists
      QuerySnapshot query = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: _auth.currentUser!.uid)
          .get();

      for (var doc in query.docs) {
        List<String> participants =
            List<String>.from((doc.data() as Map)['participants']);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      // Create new chat room
      String chatRoomId = const Uuid().v4();
      ChatRoomModel chatRoom = ChatRoomModel(
        id: chatRoomId,
        participants: [_auth.currentUser!.uid, otherUserId],
        lastMessage: {},
        createdAt: Timestamp.now(),
        unreadCount: {
          _auth.currentUser!.uid: 0,
          otherUserId: 0,
        },
      );

      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .set(chatRoom.toMap());

      return chatRoomId;
    } catch (e) {
      print('Error creating chat room: ${e.toString()}');
      return '';
    }
  }

  // Send text message
  Future<void> sendTextMessage(String chatRoomId, String receiverId,
      [String? text]) async {
    try {
      String messageText;

      if (text != null && text.isNotEmpty) {
        messageText = text;
      } else if (messageController.text.trim().isNotEmpty) {
        messageText = messageController.text.trim();
        messageController.clear();
      } else {
        return;
      }

      String messageId = const Uuid().v4();
      MessageModel message = MessageModel(
        id: messageId,
        senderId: _auth.currentUser!.uid,
        receiverId: receiverId,
        content: messageText,
        type: MessageType.text,
        timestamp: Timestamp.now(),
      );

      // Add message to chat room
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Update last message in chat room
      await _updateLastMessage(chatRoomId, message);
    } catch (e) {
      print('Error sending message: ${e.toString()}');
    }
  }

  // Send image message
  Future<void> sendImageMessage(
      String chatRoomId, String receiverId, ImageSource source) async {
    try {
      // First pick the image
      final picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(source: source);

      if (pickedImage != null) {
        // Generate messageId after picking the image
        String messageId = const Uuid().v4();
        File imageFile = File(pickedImage.path);

        // Create a message with the local file path and uploading status
        MessageModel tempMessage = MessageModel(
          id: messageId,
          senderId: _auth.currentUser!.uid,
          receiverId: receiverId,
          content: 'Image',
          type: MessageType.image,
          timestamp: Timestamp.now(),
          mediaUrl: 'local:${imageFile.path}', // Local file path
          isUploading: true, // Mark as uploading
        );

        // Add message to chat room immediately after selection
        await _firestore
            .collection('chatRooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(messageId)
            .set(tempMessage.toMap());

        // Start uploading in background
        String imageUrl = await _uploadImage(imageFile, messageId);

        // Update message with actual URL
        MessageModel finalMessage = MessageModel(
          id: messageId,
          senderId: _auth.currentUser!.uid,
          receiverId: receiverId,
          content: 'Image',
          type: MessageType.image,
          timestamp: tempMessage.timestamp,
          mediaUrl: imageUrl,
          isUploading: false, // No longer uploading
        );

        // Update message in chat room
        await _firestore
            .collection('chatRooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(messageId)
            .update(finalMessage.toMap());

        // Update last message in chat room
        await _updateLastMessage(chatRoomId, finalMessage);
      }
    } catch (e) {
      print('Error sending image message: ${e.toString()}');
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File image, String messageId) async {
    try {
      Reference ref = _storage.ref().child('chat_images').child(messageId);
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: ${e.toString()}');
      return '';
    }
  }

  // Update last message in chat room
  Future<void> _updateLastMessage(
      String chatRoomId, MessageModel message) async {
    try {
      DocumentSnapshot roomDoc =
          await _firestore.collection('chatRooms').doc(chatRoomId).get();
      ChatRoomModel chatRoom =
          ChatRoomModel.fromMap(roomDoc.data() as Map<String, dynamic>);

      Map<String, int> unreadCount =
          Map<String, int>.from(chatRoom.unreadCount);
      for (String participantId in chatRoom.participants) {
        if (participantId != _auth.currentUser!.uid) {
          unreadCount[participantId] = (unreadCount[participantId] ?? 0) + 1;
        }
      }
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': {
          'senderId': message.senderId,
          'receiverId': message.receiverId,
          'content': message.content,
          'type': message.type.toString().split('.').last,
          'timestamp': message.timestamp,
          'isRead': message.isRead,
        },
        'unreadCount': unreadCount,
      });
    } catch (e) {
      print('Error updating last message: ${e.toString()}');
    }
  }

  // Mark all messages in a chat room as read
  Future<void> markMessagesAsRead(String chatRoomId) async {
    try {
      DocumentSnapshot roomDoc =
          await _firestore.collection('chatRooms').doc(chatRoomId).get();
      if (!roomDoc.exists) return;

      Map<String, dynamic> data = roomDoc.data() as Map<String, dynamic>;
      Map<String, int> unreadCount =
          Map<String, int>.from(data['unreadCount'] ?? {});

      unreadCount[_auth.currentUser!.uid] = 0;

      // Always update lastMessage's isRead status when current user is the receiver
      Map<String, dynamic> lastMessage =
          Map<String, dynamic>.from(data['lastMessage'] ?? {});

      // Debug output to see what's in lastMessage
      print('LastMessage before update: $lastMessage');

      if (lastMessage.isNotEmpty &&
          lastMessage['receiverId'] == _auth.currentUser!.uid) {
        // Mark message as read
        lastMessage['isRead'] = true;

        print('Updated lastMessage with isRead=true: $lastMessage');

        // Update the lastMessage in the chat room
        await _firestore.collection('chatRooms').doc(chatRoomId).update({
          'lastMessage': lastMessage,
          'unreadCount': unreadCount,
        });
      } else {
        await _firestore.collection('chatRooms').doc(chatRoomId).update({
          'unreadCount': unreadCount,
        });
      }

      // Mark individual messages as read
      QuerySnapshot unreadMessages = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: _auth.currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .get();

      // Update each message to be marked as read
      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
      }

      // Force refresh chat rooms
      refreshChatRooms();

      // Check the updated chatRoom to verify changes
      DocumentSnapshot updatedRoomDoc =
          await _firestore.collection('chatRooms').doc(chatRoomId).get();
      Map<String, dynamic> updatedData =
          updatedRoomDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> updatedLastMessage =
          Map<String, dynamic>.from(updatedData['lastMessage'] ?? {});
      print('LastMessage after all updates: $updatedLastMessage');
    } catch (e) {
      print('Error marking messages as read: ${e.toString()}');
    }
  }

  // Toggle emoji keyboard visibility
  void toggleEmojiKeyboard() {
    isEmojiVisible.value = !isEmojiVisible.value;
  }
}
