import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MiniJiraApp());
}

class MiniJiraApp extends StatelessWidget {
  const MiniJiraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini-Jira',
      debugShowCheckedModeBanner: false, // Sağ üstteki "DEBUG" yazısını kaldırır
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(), // Uygulama artık bizim giriş sayfamızla başlayacak
    );
  }
}