import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const logoBlueDark = Color(0xFF0A3695);
    return MaterialApp(
      title: '5-6-7-8',
      theme: ThemeData(
        primaryColor: logoBlueDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: logoBlueDark,
          primary: logoBlueDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: logoBlueDark,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
