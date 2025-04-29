import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Regular text styles
  static TextStyle regular({
    double size = 14.0,
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: size.sp,
      color: color,
      fontWeight: weight,
    );
  }

  // Bold text styles
  static TextStyle bold({
    double size = 14.0,
    Color color = AppColors.textPrimary,
  }) {
    return TextStyle(
      fontSize: size.sp,
      color: color,
      fontWeight: FontWeight.bold,
    );
  }

  // Heading text styles
  static TextStyle heading1 = TextStyle(
    fontSize: 24.sp,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
  );

  static TextStyle heading2 = TextStyle(
    fontSize: 20.sp,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
  );

  static TextStyle heading3 = TextStyle(
    fontSize: 18.sp,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
  );

  // WhatsApp specific text styles
  static TextStyle chatName = TextStyle(
    fontSize: 16.sp,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
  );

  static TextStyle chatMessage = TextStyle(
    fontSize: 14.sp,
    color: AppColors.textPrimary,
  );

  static TextStyle chatTime = TextStyle(
    fontSize: 12.sp,
    color: AppColors.textSecondary,
  );

  static TextStyle appBarTitle = TextStyle(
    fontSize: 18.sp,
    color: AppColors.textLight,
    fontWeight: FontWeight.bold,
  );

  static TextStyle messageText = TextStyle(
    fontSize: 16.sp,
    color: AppColors.textPrimary,
  );

  static TextStyle messageTime = TextStyle(
    fontSize: 11.sp,
    color: AppColors.textSecondary,
  );

  static TextStyle linkText = TextStyle(
    fontSize: 14.sp,
    color: AppColors.linkColor,
    decoration: TextDecoration.underline,
  );
}
