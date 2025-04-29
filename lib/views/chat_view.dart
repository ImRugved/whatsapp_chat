import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:whatsapp_flutter/views/contactprofile_view.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../widgets/message_bubble.dart';
import 'dart:io';

class ChatView extends StatefulWidget {
  const ChatView({Key? key}) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _messageController = TextEditingController();
  late String chatRoomId;
  late UserModel otherUser;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Get arguments
    final args = Get.arguments as Map<String, dynamic>;
    chatRoomId = args['chatRoomId'];
    otherUser = args['otherUser'];

    // Get messages
    _chatController.getMessages(chatRoomId);

    // Listen to focus changes for emoji keyboard
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _chatController.isEmojiVisible.value = false;
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        leadingWidth: 30,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryColor,
              backgroundImage: otherUser.profileImageUrl.isNotEmpty
                  ? CachedNetworkImageProvider(otherUser.profileImageUrl)
                  : null,
              child: otherUser.profileImageUrl.isEmpty
                  ? Text(
                      otherUser.name[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () {
                  // Navigate to contact profile view
                  Get.to(() => const ContactProfileView(), arguments: {
                    'otherUser': otherUser,
                    'chatRoomId': chatRoomId,
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      otherUser.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/wpbg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Messages
            Expanded(
              child: Obx(() {
                if (_chatController.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Send a message to start the conversation',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: _chatController.messages.length,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  itemBuilder: (context, index) {
                    final message = _chatController.messages[index];
                    final bool isMe = message.senderId ==
                        _authController.firebaseUser.value!.uid;
                    final time =
                        DateFormat('h:mm a').format(message.timestamp.toDate());

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      time: time,
                    );
                  },
                );
              }),
            ),

            // Input field
            _buildMessageInput(),

            // Emoji keyboard
            Obx(() {
              return Offstage(
                offstage: !_chatController.isEmojiVisible.value,
                child: SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      _messageController.text += emoji.emoji;
                    },
                    config: Config(
                      height: 250,
                      checkPlatformCompatibility: true,
                      emojiViewConfig: EmojiViewConfig(
                        backgroundColor: Colors.white,
                        columns: 7,
                        emojiSizeMax: 32.0,
                        verticalSpacing: 0,
                        horizontalSpacing: 0,
                        recentsLimit: 28,
                        noRecents: const Text(
                          'No Recents',
                          style: TextStyle(fontSize: 20, color: Colors.black26),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      categoryViewConfig: CategoryViewConfig(
                        initCategory: Category.RECENT,
                        backgroundColor: Colors.white,
                        indicatorColor: AppColors.primaryColor,
                        iconColor: Colors.grey,
                        iconColorSelected: AppColors.primaryColor,
                        backspaceColor: AppColors.primaryColor,
                        categoryIcons: const CategoryIcons(),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Obx(() => Icon(
                  _chatController.isEmojiVisible.value
                      ? Icons.keyboard
                      : Icons.emoji_emotions,
                  color: AppColors.textSecondary,
                )),
            onPressed: () {
              _focusNode.unfocus();
              _chatController.toggleEmojiKeyboard();
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Type a message',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.attach_file, color: AppColors.textSecondary),
                  onPressed: () {
                    // Show attachment options
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildAttachmentOptions(),
                    );
                  },
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.camera_alt,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              // Take a photo with camera
              _chatController.sendImageMessage(
                chatRoomId,
                otherUser.uid,
                ImageSource.camera,
              );
            },
          ),
          FloatingActionButton(
            mini: true,
            backgroundColor: AppColors.primaryColor,
            child: const Icon(Icons.send, color: Colors.white),
            onPressed: () {
              // Send text message
              String messageText = _messageController.text.trim();
              if (messageText.isNotEmpty) {
                _chatController.sendTextMessage(
                  chatRoomId,
                  otherUser.uid,
                  messageText,
                );
                // Clear the input field
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  Icons.insert_drive_file,
                  Colors.blue,
                  'Document',
                  () {},
                ),
                _buildAttachmentOption(
                  Icons.camera_alt,
                  Colors.red,
                  'Camera',
                  () {
                    Get.back();
                    _chatController.sendImageMessage(
                      chatRoomId,
                      otherUser.uid,
                      ImageSource.camera,
                    );
                  },
                ),
                _buildAttachmentOption(
                  Icons.photo,
                  Colors.purple,
                  'Gallery',
                  () {
                    Get.back();
                    _chatController.sendImageMessage(
                      chatRoomId,
                      otherUser.uid,
                      ImageSource.gallery,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  Icons.headset,
                  Colors.orange,
                  'Audio',
                  () {},
                ),
                _buildAttachmentOption(
                  Icons.location_on,
                  Colors.green,
                  'Location',
                  () {},
                ),
                _buildAttachmentOption(
                  Icons.person,
                  Colors.blue,
                  'Contact',
                  () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    Color color,
    String label,
    Function() onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
