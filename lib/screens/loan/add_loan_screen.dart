import 'package:flutter/material.dart';
import '../../models/loan_model.dart';
import '../../models/borrower_model.dart';
import '../../services/database_helper.dart';
import './loan_detail_screen.dart';

class AddLoanScreen extends StatefulWidget {
  final int? tripId;

  const AddLoanScreen({super.key, this.tripId});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreen();  
}

class _AddLoanScreen extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  final loanIdController = TextEditingController();
  final borrowerSearchController = TextEditingController();
  final principalAmountController = TextEditingController();
  final weeklyAmountController = TextEditingController();
  final totalWeeksController = TextEditingController();

  List<Borrower> _allBorrowers = [];
  List<Borrower> _filteredBorrowers = [];
  Borrower? _selectedBorrower;
  bool isLoading = false;
  bool _showBorrowerSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadBorrowers();
    borrowerSearchController.addListener(_filterBorrowers);
  }

  @override
  void dispose() {
    loanIdController.dispose();
    borrowerSearchController.dispose();
    principalAmountController.dispose();
    weeklyAmountController.dispose();
    totalWeeksController.dispose();
    super.dispose();
  }

  Future<void> _loadBorrowers() async {
    final borrowers = await DatabaseHelper().getBorrowers();
    setState(() {
      _allBorrowers = borrowers;
      _filteredBorrowers = borrowers;
    });
  }

  void _filterBorrowers() {
    final query = borrowerSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBorrowers = _allBorrowers;
      } else {
        _filteredBorrowers = _allBorrowers
            .where((borrower) =>
                borrower.name.toLowerCase().contains(query) ||
                borrower.borrowerId.toString().contains(query))
            .toList();
      }
      _showBorrowerSuggestions = true;
    });
  }

  void _selectBorrower(Borrower borrower) {
    setState(() {
      _selectedBorrower = borrower;
      borrowerSearchController.text = '${borrower.name} (ID: ${borrower.borrowerId})';
      _showBorrowerSuggestions = false;
    });
  }

  Future<void> _saveLoan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBorrower == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a borrower')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final principalAmount = double.parse(principalAmountController.text);
      final weeklyAmount = double.parse(weeklyAmountController.text);
      final totalWeeks = int.parse(totalWeeksController.text);
      
      final newLoan = Loan(
        loanId: loanIdController.text.isNotEmpty
            ? int.parse(loanIdController.text)
            : -1,
        borrowerId: _selectedBorrower!.borrowerId!,
        createdBy: "Admin",
        principalAmount: principalAmount,
        weeklyAmount: weeklyAmount,
        totalWeeks: totalWeeks,
        startDate: DateTime.now().toString(),
        status: 'Active',
        createdAt: DateTime.now().toString(),
        isSynced: 0,
      );

      final loanId = await DatabaseHelper().insertLoan(newLoan);
      
      // If adding loan from a trip, add it to trip_items
      if (widget.tripId != null) {
        final db = await DatabaseHelper().database;
        await db.insert('trip_items', {
          'trip_id': widget.tripId,
          'loan_id': loanId,
          'borrower_id': _selectedBorrower!.borrowerId,
          'expected_amount': weeklyAmount * totalWeeks,
          'collected_amount': 0,
          'status': 'new',
          'created_at': DateTime.now().toString(),
        });
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving loan: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Loan'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loan ID Field (Auto-generated)
                    const Text(
                      'Loan ID',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: loanIdController,
                      decoration: InputDecoration(
                        hintText: 'Loan No',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Borrower Search Field
                    const Text(
                      'Select Borrower',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: borrowerSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search borrower by name or ID...',
                        prefixIcon: const Icon(Icons.person_search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: _selectedBorrower != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _selectedBorrower = null;
                                    borrowerSearchController.clear();
                                    _showBorrowerSuggestions = false;
                                  });
                                },
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (_selectedBorrower == null) {
                          return 'Please select a borrower';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    // Borrower Suggestions List
                    if (_showBorrowerSuggestions && _filteredBorrowers.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredBorrowers.length,
                          itemBuilder: (context, index) {
                            final borrower = _filteredBorrowers[index];
                            return ListTile(
                              title: Text(borrower.name),
                              subtitle: Text(
                                'ID: ${borrower.borrowerId} | Phone: ${borrower.phone}',
                              ),
                              onTap: () => _selectBorrower(borrower),
                            );
                          },
                        ),
                      )
                    else if (_showBorrowerSuggestions && borrowerSearchController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'No borrowers found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Principal Amount
                    TextFormField(
                      controller: principalAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Principal Amount (₹)',
                        prefixIcon: const Icon(Icons.money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter principal amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Weekly Amount
                    TextFormField(
                      controller: weeklyAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Weekly Amount (₹)',
                        prefixIcon: const Icon(Icons.receipt),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter weekly amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Total Weeks
                    TextFormField(
                      controller: totalWeeksController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Total Weeks',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter total weeks';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveLoan,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          'Create Loan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}