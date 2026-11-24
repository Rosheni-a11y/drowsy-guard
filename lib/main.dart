import 'package:flutter/material.dart';
import 'screens/camera_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DrowsyGuardApp());
}

class DrowsyGuardApp extends StatelessWidget {
  const DrowsyGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drowsy Guard',
      theme: ThemeData.dark(),
      home: const CameraScreen(),
    );
  }
}
