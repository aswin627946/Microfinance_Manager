import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../services/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _borrowerCount = 0;
  int _loanCount = 0;
  bool _isLoading = true;
  
  // Subscription for listening to incoming intents while the app is running
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _setupIntentListener();
  }

  void _setupIntentListener() {
    // 1. Handle Hot Start (App is already in memory and running in background)
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          _processIncomingDatabase(value.first.path);
        }
      },
      onError: (err) {
        debugPrint("Intent Stream Error: $err");
      },
    );

    // 2. Handle Cold Start (App was completely closed and opened via the file)
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _processIncomingDatabase(value.first.path);
        // Clear the intent so it doesn't fire again accidentally
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  Future<void> _processIncomingDatabase(String incomingFilePath) async {
    // Verify it is a database file
    if (!incomingFilePath.endsWith('.db') && !incomingFilePath.endsWith('.sqlite')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid file format. Expected .db or .sqlite')),
        );
      }
      return;
    }

    // Ask user for confirmation
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Database?'),
        content: const Text('This will overwrite all your current app data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Overwrite', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _importDatabaseFromPath(incomingFilePath);
    }
  }

  Future<void> _importDatabaseFromPath(String filePath) async {
    setState(() => _isLoading = true);

    try {
      File selectedFile = File(filePath);
      
      // Get the path where your app's database is stored
      final dbFolder = await getDatabasesPath();
      
      // IMPORTANT: Replace 'microfinance_manager.db' with your actual database name
      final dbPath = path.join(dbFolder, 'microfinance_manager.db'); 
      
      // Overwrite the existing database with the incoming file
      await selectedFile.copy(dbPath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database imported successfully!')),
        );
        // Reload the UI stats to reflect the newly imported data
        await _loadStats(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final borrowers = await DatabaseHelper().getBorrowers();
      final loans = await DatabaseHelper().getLoans();
      
      if (mounted) {
        setState(() {
          _borrowerCount = borrowers.length;
          _loanCount = loans.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle the case where the database might be temporarily locked or unavailable
      debugPrint("Error loading stats: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Database',
            onPressed: () async {
              await DatabaseHelper().exportDatabase();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database exported successfully')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Import Database',
            onPressed: () async {
              // This triggers your manual FilePicker import logic inside DatabaseHelper
              await DatabaseHelper().importDatabase();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database imported successfully')),
                );
                // Reload stats after manual import
                _loadStats();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('Borrowers', _borrowerCount, Colors.blue),
                      _buildStatCard('Loans', _loanCount, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'App Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text('App: Microfinance Manager'),
                          Text('Version: 1.0.0'),
                          Text('Database: SQLite'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}