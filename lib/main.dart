import 'package:booktracker/home.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BookTracker());
}

class BookTracker extends StatefulWidget {
  const BookTracker({super.key});

  @override
  State<BookTracker> createState() => _BookTrackerState();
}

class _BookTrackerState extends State<BookTracker> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookTracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}
