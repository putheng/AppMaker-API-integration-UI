import 'package:flutter/material.dart';

import 'screens/builder_shell.dart';
import 'theme/theme.dart';

class AppMakerApp extends StatelessWidget {
  const AppMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppMaker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const BuilderShell(),
    );
  }
}
