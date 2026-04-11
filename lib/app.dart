import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/routes/app_routes.dart';
import 'package:aifin/features/auth/screens/signup_screen.dart';
import 'package:aifin/features/dashboard/screens/dashboard_screen.dart';
import 'package:aifin/core/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AiFinApp extends ConsumerWidget {
  const AiFinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    
    return MaterialApp(
      title: 'AIFin Finance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurpleAccent,
          secondary: Colors.tealAccent,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      // Hook up custom routing
      onGenerateRoute: AppRoutes.generateRoute,
      // Dynamic Home: Skips log-on flow if session is active!
      home: user != null ? const DashboardScreen() : const SignupScreen(),
    );
  }
}
