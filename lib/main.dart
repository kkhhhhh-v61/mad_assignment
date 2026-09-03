import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'splash_screen.dart';

const String supabaseUrl =
String.fromEnvironment('SUPABASE_URL');

const String supabasePublishableKey =
String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

SupabaseClient get supabase => Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    runApp(const MissingSupabaseConfigurationApp());
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const MyApp());
}

class MissingSupabaseConfigurationApp extends StatelessWidget {
  const MissingSupabaseConfigurationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Supabase configuration is missing. Run with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY dart defines.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
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
