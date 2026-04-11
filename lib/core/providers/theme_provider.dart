import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

class ThemeNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return {
      'theme': prefs.getString('theme') ?? 'light',
      'themeAccent': prefs.getString('themeAccent') ?? 'Deep Purple',
    };
  }

  void updateTheme(String themeString) {
    ref.read(sharedPreferencesProvider).setString('theme', themeString);
    state = {...state, 'theme': themeString};
  }
  
  void updateAccent(String accentString) {
    ref.read(sharedPreferencesProvider).setString('themeAccent', accentString);
    state = {...state, 'themeAccent': accentString};
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, Map<String, String>>(() {
  return ThemeNotifier();
});
