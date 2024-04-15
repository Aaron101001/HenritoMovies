import 'package:flutter/material.dart';
import 'dashboard/dashboard.dart';

void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(),
      home: const RecentMovies(),
    );
  }
}
