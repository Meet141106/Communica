import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rwxyzkbloszbqhrvhbyz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3eHl6a2Jsb3N6YnFocnZoYnl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk2Mzg4NTYsImV4cCI6MjA1NTIxNDg1Nn0.Dlfgf3Xx6sdlykVl50dyYU9OrSTH961o7noWCnEcFjA',
);

  // Request storage permission
  await Permission.storage.request();

  runApp(const CommunicaApp());
}

class CommunicaApp extends StatelessWidget {
  const CommunicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      title: 'Communica',
    );
  }
}

/* import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rwxyzkbloszbqhrvhbyz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3eHl6a2Jsb3N6YnFocnZoYnl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk2Mzg4NTYsImV4cCI6MjA1NTIxNDg1Nn0.Dlfgf3Xx6sdlykVl50dyYU9OrSTH961o7noWCnEcFjA'
  );

  // Only request permissions on non-web platforms
  if (!kIsWeb) {
    // Remove permission_handler if not needed
    // await Permission.storage.request();
  }

  runApp(const CommunicaApp());
}

class CommunicaApp extends StatelessWidget {
  const CommunicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Communica',
      home: SplashScreen(), 
    );
  }
} */