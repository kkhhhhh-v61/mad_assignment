import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'splash_screen.dart';

const String supabaseUrl = "https://xjumxpsalmmyboqlvand.supabase.co";
const String supabaseKey = "sb_secret_mGhPh1mK9Jd15cPGmlMt3w_mvsJ9uLs";

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DoorDish',
      home: const SplashScreen(),
    );
  }
}
