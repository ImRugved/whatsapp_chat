import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_room_model.dart';
import '../models/user_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final ChatController _chatController = Get.put(ChatController());
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authController.updateUserStatus(true);

    // Explicitly refresh chat rooms when view initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatController.refreshChatRooms();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _authController.updateUserStatus(true);
    } else {
      _authController.updateUserStatus(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authController.updateUserStatus(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        title: Text(
          'Whatsapp',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _authController.signOut();
              } else if (value == 'profile') {
                Get.toNamed('/profile');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Profile'),
              ),
              const PopupMenuItem(
                value: 'newgroup',
                child: Text('New group'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          )
        ],
      ),
      body: Obx(() {
        if (_chatController.chatRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No chats yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation by tapping on the button below',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: _chatController.chatRooms.length,
          itemBuilder: (context, index) {
            ChatRoomModel chatRoom = _chatController.chatRooms[index];

            // Get the other participant's ID
            String otherUserId = chatRoom.participants.firstWhere(
              (id) => id != _authController.firebaseUser.value!.uid,
              orElse: () => '',
            );

            // Find user from contacts
            UserModel? otherUser = _chatController.contacts.firstWhereOrNull(
              (user) => user.uid == otherUserId,
            );

            if (otherUser == null) {
              return const SizedBox();
            }

            // Unread count for current user
            int unreadCount =
                chatRoom.unreadCount[_authController.firebaseUser.value!.uid] ??
                    0;

            // Last message timestamp
            String time = '';
            if (chatRoom.lastMessage.isNotEmpty &&
                chatRoom.lastMessage.containsKey('timestamp')) {
              // Convert Firebase Timestamp to DateTime
              DateTime messageTime;
              var timestamp = chatRoom.lastMessage['timestamp'];

              if (timestamp is DateTime) {
                messageTime = timestamp;
              } else if (timestamp != null) {
                // Convert Firebase Timestamp to DateTime
                messageTime = DateTime.fromMillisecondsSinceEpoch(
                    (timestamp as dynamic).millisecondsSinceEpoch);
              } else {
                messageTime = DateTime.now();
              }

              DateTime now = DateTime.now();

              if (now.difference(messageTime).inDays == 0) {
                // Today, just show time in 12-hour format
                time = DateFormat('h:mm a').format(messageTime);
              } else if (now.difference(messageTime).inDays == 1) {
                // Yesterday
                time = 'Yesterday';
              } else if (now.difference(messageTime).inDays < 7) {
                // Within a week
                time = DateFormat('EEEE').format(messageTime);
              } else {
                // More than a week
                time = DateFormat('dd/MM/yyyy').format(messageTime);
              }
            }

            return ListTile(
              leading: CircleAvatar(
                radius: 24,
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
              title: Text(
                otherUser.name,
                style: TextStyle(
                  fontWeight:
                      unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Row(
                children: [
                  if (chatRoom.lastMessage.isNotEmpty)
                    if (chatRoom.lastMessage['senderId'] ==
                        _authController.firebaseUser.value!.uid)
                      Icon(
                        chatRoom.lastMessage.containsKey('isRead') &&
                                chatRoom.lastMessage['isRead'] == true
                            ? Icons.done_all
                            : Icons.done,
                        size: 16,
                        color: chatRoom.lastMessage.containsKey('isRead') &&
                                chatRoom.lastMessage['isRead'] == true
                            ? AppColors.accentColor
                            : Colors.grey,
                      ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      chatRoom.lastMessage.isNotEmpty
                          ? chatRoom.lastMessage['content'] ?? ''
                          : 'Start a conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: unreadCount > 0
                          ? AppColors.accentColor
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Get.toNamed('/chat', arguments: {
                  'chatRoomId': chatRoom.id,
                  'otherUser': otherUser,
                });
              },
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.fabColor,
        child: const Icon(Icons.chat, color: Colors.white),
        onPressed: () => Get.toNamed('/contacts'),
      ),
    );
  }
}
