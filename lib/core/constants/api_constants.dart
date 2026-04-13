class ApiConstants {
  // 💡 GOOGLE GEMINI AI CONFIGURATION
  // Get your key from: https://aistudio.google.com/app/apikey
  static const String geminiApiKey = 'AIzaSyBXMvvGJwUTp1kS-dKp8g7c_sIeNKJFQWM';

  // Model version used for high-speed financial analysis
  static const String geminiModel = 'gemini-3-flash-preview';

  // Base endpoints for any future external APIs (OpenWeather, Currencies, etc.)
  static const String baseUrl = 'https://api.aifinance.com/v1';

  // Timeout settings
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;
}
