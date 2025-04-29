import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String time;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget messageContent;
    switch (message.type) {
      case MessageType.text:
        messageContent = Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.black : Colors.black,
            fontSize: 16,
          ),
        );
        break;

      case MessageType.image:
        bool isLocalImage = message.mediaUrl.startsWith('local:');
        String imagePath = isLocalImage
            ? message.mediaUrl.substring(6) // Remove 'local:' prefix
            : message.mediaUrl;

        messageContent = Container(
          width: 200, // Fixed width
          height: 200, // Fixed height
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Placeholder/background while loading
                Container(
                  color: AppColors.chatBubbleMine.withOpacity(0.3),
                  width: 200,
                  height: 200,
                ),

                // Image (either local or from network)
                isLocalImage
                    ? Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        width: 200,
                        height: 200,
                      )
                    : CachedNetworkImage(
                        imageUrl: imagePath,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryColor),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        fit: BoxFit.cover,
                        width: 200,
                        height: 200,
                      ),

                // Loading indicator overlay if still uploading
                if (message.isUploading)
                  Container(
                    width: 200,
                    height: 200,
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
        break;

      default:
        messageContent = Text(message.content);
        break;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 80 : 8,
          right: isMe ? 8 : 80,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? AppColors.chatBubbleMine : AppColors.chatBubbleOther,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMe ? 12 : 0),
            topRight: Radius.circular(isMe ? 0 : 12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            messageContent,
            SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 5),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.isRead ? AppColors.accentColor : Colors.grey,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
