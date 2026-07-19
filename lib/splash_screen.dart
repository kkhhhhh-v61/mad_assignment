import 'config.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mad_assignment/customer_main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // delay navigation by 3 seconds
    Timer(const Duration(seconds: 3), () {
      // navigates to customer home page
      // pushReplacement removes splash_screen.dart from the navigation history
      // making customer_home.dart the first page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const CustomerMainNavigation(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Center(
          child: SizedBox(
            height: 300,
            width: 300,
            child: Image.asset(appLogo),
          ),
        ),
      ),
    );
  }
}
