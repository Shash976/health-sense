import 'dart:convert';
import 'dart:async';
import 'package:bio_amp/welcome.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WelcomePage(),
    );
  }
}
