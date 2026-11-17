import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.darkBrown,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.darkBrown,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.darkBrown,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    color: AppColors.brown,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.darkBrown,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.mutedText,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
  );
}
