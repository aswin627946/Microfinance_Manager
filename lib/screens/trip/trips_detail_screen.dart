import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../models/trip_item_model.dart';
import '../../models/borrower_model.dart';
import '../../services/phone_dialer.dart';
import '../borrower/borrower_detail_screen.dart';
import '../loan/add_loan_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  List<TripItem> newLoans = [];
  List<TripItem> pending = [];
  List<TripItem> partial = [];
  List<TripItem> completed = [];
  Map<String, dynamic> summary = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    final db = await DatabaseHelper().database;

    newLoans =
        await DatabaseHelper().getTripItems(db, widget.tripId, 'new');
    pending =
        await DatabaseHelper().getTripItems(db, widget.tripId, 'pending');
    partial =
        await DatabaseHelper().getTripItems(db, widget.tripId, 'partial');
    completed =
        await DatabaseHelper().getTripItems(db, widget.tripId, 'completed');

      summary = await DatabaseHelper().getTripSummary(db, widget.tripId);

    setState(() {});
  }

  void makePayment(TripItem item) {
    final controller = TextEditingController();
    String selectedPaymentType = 'cash';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Payment"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Payment Method:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Cash Option
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RadioListTile<String>(
                    title: const Text('Cash'),
                    value: 'cash',
                    groupValue: selectedPaymentType,
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentType = value ?? 'cash';
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // UPI Option
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RadioListTile<String>(
                    title: const Text('UPI'),
                    value: 'upi',
                    groupValue: selectedPaymentType,
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentType = value ?? 'cash';
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Enter Amount:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter amount in ₹',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.currency_rupee),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                double amount = double.tryParse(controller.text) ?? 0;

                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                final db = await DatabaseHelper().database;

                await DatabaseHelper().insertPayment(
                  db: db,
                  tripId: widget.tripId,
                  loanId: item.loanId,
                  borrowerId: item.borrowerId,
                  amountPaid: amount,
                  paymentType: selectedPaymentType,
                );

                Navigator.pop(context);
                loadData();
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }

  Color getColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green.shade100;
      case 'partial':
        return Colors.orange.shade100;
      default:
        return Colors.red.shade100;
    }
  }

  Widget buildItem(TripItem item) {
    return FutureBuilder<Borrower?>(
      future: DatabaseHelper().getBorrowerById(item.borrowerId),
      builder: (_, snapshot) {
        final Borrower borrower = snapshot.data ??Borrower(  
                    borrowerId: -1,
                    name: "Unknown Borrower",
                    status: 0,
                    phone: "9999999999",
                    address: "123 Main St",
                    latitude: 0.0,
                    longitude: 0.0,
                    city:"unknown",
                    createdAt: DateTime.now().toString(),
                    isSynced: 0,
                  );

        return GestureDetector(
          onTap:(){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:(context)=>
                          BorrowerDetailScreen(borrower:borrower),
                        ),);
                    },
          child: Card(
            color: getColor(item.status),
            child: ListTile(
              title: Text(borrower?.name ?? ""),
              subtitle: Text(
                "₹${item.collectedAmount} / ₹${item.expectedAmount}"),
            trailing: item.status != 'completed'
                ?Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.payment),
                      onPressed: () => makePayment(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.call),
                      onPressed: () => callPhoneNumber(borrower?.phone ?? ""),
                    ),  
                  ],
                )
                : const Icon(Icons.check, color: Colors.green),
          ),
        )
        );
      },
    );
  }

  Widget buildSummary() {
    // Calculate sum of new loans
    double newLoansTotalAmount = newLoans.fold(0, (sum, item) => sum + item.expectedAmount);
    
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Total Loans: ${summary['totalLoans']}"),
            Text("Expected: ₹${summary['expected']}"),
            Text("Collected: ₹${summary['collected']} (Cash: ₹${summary['collectedCash']}, UPI: ₹${summary['collectedUpi']})"),
            Text("Remaining: ₹${summary['remaining']}"),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'New Loans Added: ',
                    style: TextStyle( color: Colors.blue),
                  ),
                  Text(
                    '₹${newLoansTotalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildList(List<TripItem> list) {
    if (list.isEmpty) {
      return const Center(child: Text("No items"));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => buildItem(list[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trip #${widget.tripId}"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "New Loans"),
            Tab(text: "Pending"),
            Tab(text: "Partial"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: Column(
        children: [
          buildSummary(),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildList(newLoans),
                buildList(pending),
                buildList(partial),
                buildList(completed),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddLoanScreen(tripId: widget.tripId),
                      ),
                    );
                    if (result == true) {
                      loadData();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Loan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await DatabaseHelper().closeTrip(widget.tripId);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text("Close Trip"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}