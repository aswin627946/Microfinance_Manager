import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb; // Needed to detect Web
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Needed for Web
import 'screens/home_screen.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Check if running on the Web
  if (kIsWeb) {
    // Change default factory to the web-based WebAssembly factory
    databaseFactory = databaseFactoryFfiWeb;
  } 
  // 2. If NOT web, check if running on Desktop
  else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialize standard FFI and change the factory
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // 3. Mobile (iOS/Android) requires no factory changes, it works automatically!

  // Initialize database
  await DatabaseHelper().database;
  print('✓ Database initialized successfully');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SQLite Offline-First',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}