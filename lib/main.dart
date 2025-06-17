import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(SmartCareApp());
}

class SmartCareApp extends StatelessWidget {
  const SmartCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCare',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Color(0xFF10B981), // Emerald-500
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF10B981),
          secondary: Color(0xFF0D9488), // Teal-600
        ),
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}