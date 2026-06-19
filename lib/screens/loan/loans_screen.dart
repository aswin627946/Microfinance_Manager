import 'package:flutter/material.dart';
import '../../models/loan_model.dart';
import '../../services/database_helper.dart';
import 'add_loan_screen.dart';
import 'loan_detail_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  _LoansScreenState createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  List<Loan> _loans = [];
  List<Loan> _filteredLoans = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshLoans();
    _searchController.addListener(_filterLoans);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshLoans() async {
    final loans = await DatabaseHelper().getLoans();
    setState(() {
      _loans = loans;
      _filteredLoans = loans;
      _isLoading = false;
    });
  }

  void _filterLoans() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredLoans = _loans;
      } else {
        _filteredLoans = _loans
            .where((loan) => loan.loanId.toString().contains(query))
            .toList();
      }
    });
  }

  Future<String> _getBorrowerName(int borrowerId) async {
    final borrower = await DatabaseHelper().getBorrowerById(borrowerId);
    return borrower?.name ?? 'Unknown Borrower';
  }

  Future<void> _addLoan() async {
    // final newLoan = Loan(
    //   loanId: 0,
    //   borrowerId: 1,
    //   createdBy: "Admin",
    //   principalAmount: 10000,
    //   weeklyAmount: 500,
    //   totalWeeks: 25,
    //   startDate: DateTime.now().toString(),
    //   status: "Active",
    //   createdAt: DateTime.now().toString(),
    //   isSynced: 0,
    // );
    // await DatabaseHelper().insertLoan(newLoan);
    // _refreshLoans();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddLoanScreen(),

      ),
    );

    if (result == true) {
      _refreshLoans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Search by loan ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterLoans();
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
                : _filteredLoans.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'No loans yet. Add one!'
                              : 'No loans found matching "${_searchController.text}"',
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredLoans.length,
                        itemBuilder: (context, index) {
                          final loan = _filteredLoans[index];
                          final amount = loan.weeklyAmount * loan.totalWeeks;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LoanDetailScreen(loan: loan),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: FutureBuilder<String>(
                                future: _getBorrowerName(loan.borrowerId),
                                builder: (context, snapshot) {
                                  final borrowerName =
                                      snapshot.data ?? 'Loading...';
                                  return ListTile(
                                    title: Text('Loan #${loan.loanId}'),
                                    subtitle: Text(
                                        'Borrower: $borrowerName | Amount: ₹${amount.toStringAsFixed(2)}'),
                                    trailing: Chip(
                                      label: loan.status == '1'
                                          ? const Text('Active')
                                          : const Text('Inactive'),
                                      backgroundColor:
                                          loan.status == '1'
                                              ? Colors.green
                                              : Colors.orange,
                                      labelStyle:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLoan,
        tooltip: 'Add Loan',
        child: const Icon(Icons.add),
      ),
    );
  }
}
