import 'package:flutter/material.dart';
import 'package:login_signup/screens/welcome_screen.dart';
import 'theme/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Tracker App',
      theme: lightMode,
      home: const SignInScreen(),
    );
  }
}
