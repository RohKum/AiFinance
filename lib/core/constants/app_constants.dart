import 'package:flutter/material.dart';

class AppConstants {
  // ==========================================
  // App Information
  // ==========================================
  static const String appName = 'AIFin Finance';
  static const String appVersion = '1.0.0';

  // ==========================================
  // Localization & Formatting
  // ==========================================
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // ==========================================
  // Networking / API (Ideally load from .env)
  // ==========================================
  static const String apiBaseUrl = 'https://api.aifin.com/v1';
  static const int connectionTimeout = 30000; // ms
  static const int receiveTimeout = 30000; // ms

  // ==========================================
  // Local SharedPrefs / Hive Storage Keys
  // ==========================================
  static const String keyUserToken = 'user_token';
  static const String keyThemeMode = 'theme_mode';
  static const String keyIsFirstTimeLaunch = 'is_first_time_launch';

  // ==========================================
  // UI Layout Constants
  // ==========================================
  static const double paddingLarge = 24.0;
  static const double paddingNormal = 16.0;
  static const double paddingSmall = 8.0;
  
  static const double borderRadiusCard = 24.0;
  static const double borderRadiusButton = 12.0;

  // ==========================================
  // Financial Categories
  // ==========================================
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Health',
    'Other'
  ];

  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Other'
  ];
}

class AppColors {
  // ==========================================
  // Centralized Application Colors
  // ==========================================
  static const Color backgroundLight = Color(0xFFF7F9FC);
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF757575);

  // Gradient Colors
  static const Color primaryGradientStart = Color(0xFF5E35B1);
  static const Color primaryGradientEnd = Color(0xFF7E57C2);

  // Status Colors
  static const Color incomeGreen = Colors.greenAccent;
  static const Color expenseRed = Colors.redAccent;
  
  // Accents
  static const Color aiAccentColor = Colors.deepPurpleAccent;
}
