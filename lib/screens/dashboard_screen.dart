import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final borrowers = await DatabaseHelper().getBorrowers();
    final loans = await DatabaseHelper().getLoans();
    
    setState(() {
      _borrowerCount = borrowers.length;
      _loanCount = loans.length;
      _isLoading = false;
    });
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
              await DatabaseHelper().importDatabase();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database imported successfully')),
                );
                // Reload stats after import
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
