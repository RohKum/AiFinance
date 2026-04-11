import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:aifin/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android pulls mapping configs straight from google-services.json natively
  await Firebase.initializeApp();
  await GoogleSignIn.instance.initialize();
  
  runApp(const ProviderScope(child: AiFinApp()));
}

