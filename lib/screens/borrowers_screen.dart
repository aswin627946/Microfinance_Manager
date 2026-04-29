import 'package:flutter/material.dart';
import '../models/borrower_model.dart';
import '../services/database_helper.dart';
import 'borrower_detail_screen.dart';

class BorrowersScreen extends StatefulWidget {
  const BorrowersScreen({super.key});

  @override
  _BorrowersScreenState createState() => _BorrowersScreenState();
}

class _BorrowersScreenState extends State<BorrowersScreen> {
  List<Borrower> _borrowers = [];
  List<Borrower> _filteredBorrowers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshBorrowers();
    _searchController.addListener(_filterBorrowers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshBorrowers() async {
    final borrowers = await DatabaseHelper().getBorrowers();
    setState(() {
      _borrowers = borrowers;
      _filteredBorrowers = borrowers;
      _isLoading = false;
    });
  }

  void _filterBorrowers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBorrowers = _borrowers;
      } else {
        _filteredBorrowers = _borrowers
            .where((borrower) => borrower.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _addBorrower() async {
    final newBorrower = Borrower(
      borrowerId: 0,
      name: "New Borrower",
      status: 1,
      phone: "123-456-7890",
      address: "123 Main St",
      latitude: 0.0,
      longitude: 0.0,
      createdAt: DateTime.now().toString(),
      isSynced: 0,
    );
    await DatabaseHelper().insertBorrower(newBorrower);
    _refreshBorrowers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrowers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterBorrowers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBorrowers.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'No borrowers yet. Add one!'
                              : 'No borrowers found matching "${_searchController.text}"',
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredBorrowers.length,
                        itemBuilder: (context, index) {
                          final borrower = _filteredBorrowers[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BorrowerDetailScreen(borrower: borrower),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: ListTile(
                                title: Text(borrower.name),
                                subtitle: Text(borrower.phone),
                                trailing: Icon(
                                  borrower.isSynced == 1
                                      ? Icons.cloud_done
                                      : Icons.cloud_off,
                                  color: borrower.isSynced == 1
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBorrower,
        tooltip: 'Add Borrower',
        child: const Icon(Icons.add),
      ),
    );
  }
}
