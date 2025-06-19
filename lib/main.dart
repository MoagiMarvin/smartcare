import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'database/database_helper.dart';

void main() async {
  // Ensure that widget binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await _initializeDatabase();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(SmartCareApp());
}

Future<void> _initializeDatabase() async {
  try {
    // Initialize database helper to create tables and default data
    final dbHelper = DatabaseHelper();
    await dbHelper.database; // This will trigger database creation
    print('Database initialized successfully');
  } catch (e) {
    print('Error initializing database: $e');
  }
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