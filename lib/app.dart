import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/routes/app_routes.dart';
import 'package:aifin/features/auth/screens/signup_screen.dart';
import 'package:aifin/features/dashboard/screens/dashboard_screen.dart';
import 'package:aifin/core/providers/user_provider.dart';
import 'package:aifin/core/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AiFinApp extends ConsumerWidget {
  const AiFinApp({super.key});

  Color _getSeedColor(String? accentName) {
    if (accentName == 'Emerald Green') return Colors.teal;
    if (accentName == 'Midnight Blue') return const Color(0xFF191970);
    if (accentName == 'Ruby Red') return Colors.redAccent;
    return Colors.deepPurple;
  }

  Color _getPrimaryColor(String? accentName) {
    if (accentName == 'Emerald Green') return Colors.tealAccent.shade700;
    if (accentName == 'Midnight Blue') return Colors.indigoAccent;
    if (accentName == 'Ruby Red') return Colors.redAccent;
    return Colors.deepPurpleAccent;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final themeState = ref.watch(themeProvider);
    
    final isDark = themeState['theme'] == 'dark';
    final accent = themeState['themeAccent'];

    final primaryColor = _getPrimaryColor(accent);

    return MaterialApp(
      title: 'AIFin Finance',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: _getSeedColor(accent),
          primary: primaryColor,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFFF7F9FC),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: _getSeedColor(accent),
          primary: primaryColor,
          surface: const Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        useMaterial3: true,
      ),
      // Hook up custom routing
      onGenerateRoute: AppRoutes.generateRoute,
      // Dynamic Home: Skips log-on flow if session is active!
      home: user != null ? const DashboardScreen() : const SignupScreen(),
    );
  }
}
