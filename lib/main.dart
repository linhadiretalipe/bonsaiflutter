import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';

void main() {
  runApp(const ProviderScope(child: BonsaiApp()));
}

class BonsaiApp extends StatelessWidget {
  const BonsaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bonsai Mobile',
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
