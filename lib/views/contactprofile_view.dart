import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../controllers/chat_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class ContactProfileView extends StatefulWidget {
  const ContactProfileView({Key? key}) : super(key: key);

  @override
  State<ContactProfileView> createState() => _ContactProfileViewState();
}

class _ContactProfileViewState extends State<ContactProfileView> {
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late UserModel otherUser;
  late String chatRoomId;
  final RxList<MessageModel> sharedMedia = <MessageModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();

    // Get arguments
    final args = Get.arguments as Map<String, dynamic>;
    otherUser = args['otherUser'];
    chatRoomId = args['chatRoomId'];

    // Load shared media
    _loadSharedMedia();
  }

  Future<void> _loadSharedMedia() async {
    try {
      isLoading.value = true;

      // Get all image messages from the chat
      QuerySnapshot snapshot = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('type', isEqualTo: 'image')
          .orderBy('timestamp', descending: true)
          .limit(30) // Limit to 30 most recent images
          .get();

      List<MessageModel> media = [];
      for (var doc in snapshot.docs) {
        media.add(MessageModel.fromMap(doc.data() as Map<String, dynamic>));
      }

      sharedMedia.value = media;
    } catch (e) {
      print('Error loading shared media: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Profile Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.appBarColor,
            flexibleSpace: FlexibleSpaceBar(
              background: otherUser.profileImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: otherUser.profileImageUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.primaryColor,
                      child: Center(
                        child: Text(
                          otherUser.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // User Info Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    otherUser.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Phone Number
                  Text(
                    otherUser.phoneNumber,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Online Status
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color:
                              otherUser.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        otherUser.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.call,
                        label: 'Call',
                        onTap: () {
                          // Implement call functionality
                          Get.snackbar(
                            'Call',
                            'Calling ${otherUser.name}...',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.videocam,
                        label: 'Video',
                        onTap: () {
                          // Implement video call functionality
                          Get.snackbar(
                            'Video Call',
                            'Video calling ${otherUser.name}...',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.currency_rupee,
                        label: 'Pay',
                        onTap: () {
                          // Implement payment functionality
                          Get.snackbar(
                            'Payment',
                            'Payment feature coming soon!',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.search,
                        label: 'Search',
                        onTap: () {
                          // Implement search functionality
                          Get.snackbar(
                            'Search',
                            'Search feature coming soon!',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),

                  // Status
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Status'),
                    subtitle: Text(otherUser.status),
                  ),

                  const Divider(),

                  // Media, Links, and Docs
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                    child: Text(
                      'Media, Links, and Docs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Shared Media Grid
          Obx(() {
            if (isLoading.value) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (sharedMedia.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No media shared yet'),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final message = sharedMedia[index];
                    return GestureDetector(
                      onTap: () {
                        // Show full-screen image
                        Get.dialog(
                          Dialog(
                            insetPadding: EdgeInsets.zero,
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: message.mediaUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Get.back(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'media_${message.id}',
                        child: CachedNetworkImage(
                          imageUrl: message.mediaUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: sharedMedia.length,
                ),
              ),
            );
          }),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primaryColor,
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
