import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const WorkoutApp());
}

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3B82F6);
    return MaterialApp(
      title: '심플 운동 기록장',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
