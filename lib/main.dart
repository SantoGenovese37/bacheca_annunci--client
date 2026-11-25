import 'package:flutter/material.dart';
import 'package:flutter_app/api_service.dart';
import 'package:flutter_app/public_board_screen.dart';

void main() {
  final api = ApiService(baseUrl: 'http://10.168.125.49:8080');
  runApp(JobBoardApp(api: api));
}

class JobBoardApp extends StatelessWidget {
  final ApiService api;

  const JobBoardApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bacheca Lavoro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: PublicBoardScreen(api: api),
    );
  }
}