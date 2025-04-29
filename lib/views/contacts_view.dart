import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/user_model.dart';

class ContactsView extends StatelessWidget {
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();

  ContactsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        title: Text(
          'Select Contact',
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
        ],
      ),
      body: Obx(() {
        if (_chatController.contacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_search,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No contacts found',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: _chatController.contacts.length,
          itemBuilder: (context, index) {
            UserModel contact = _chatController.contacts[index];

            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryColor,
                backgroundImage: contact.profileImageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(contact.profileImageUrl)
                    : null,
                child: contact.profileImageUrl.isEmpty
                    ? Text(
                        contact.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(
                contact.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                contact.status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: contact.isOnline
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.onlineStatus,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
              onTap: () async {
                // Create or get existing chat room
                String chatRoomId =
                    await _chatController.createOrGetChatRoom(contact.uid);

                if (chatRoomId.isNotEmpty) {
                  Get.toNamed('/chat', arguments: {
                    'chatRoomId': chatRoomId,
                    'otherUser': contact,
                  });
                }
              },
            );
          },
        );
      }),
    );
  }
}
