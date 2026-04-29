import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/trip_item_model.dart';
import '../models/borrower_model.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  List<TripItem> pending = [];
  List<TripItem> partial = [];
  List<TripItem> completed = [];
  Map<String, dynamic> summary = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    final db = await DatabaseHelper().database;

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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Payment"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              double amount =
                  double.tryParse(controller.text) ?? 0;

              final db = await DatabaseHelper().database;

              await DatabaseHelper().insertPayment(
                db: db,
                tripId: widget.tripId,
                loanId: item.loanId,
                borrowerId: item.borrowerId,
                amountPaid: amount,
                paymentType: 'cash',
              );

              Navigator.pop(context);
              loadData();
            },
            child: const Text("Save"),
          )
        ],
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
      builder: (_, snap) {
        final borrower = snap.data;

        return Card(
          color: getColor(item.status),
          child: ListTile(
            title: Text(borrower?.name ?? ""),
            subtitle: Text(
                "₹${item.collectedAmount} / ₹${item.expectedAmount}"),
            trailing: item.status != 'completed'
                ? IconButton(
                    icon: const Icon(Icons.payment),
                    onPressed: () => makePayment(item),
                  )
                : const Icon(Icons.check, color: Colors.green),
          ),
        );
      },
    );
  }

  Widget buildSummary() {
    if (summary == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total Loans: ${summary!['totalLoans']}"),
            Text("Expected: ₹${summary!['expected']}"),
            Text("Collected: ₹${summary!['collected']}"),
            Text("Remaining: ₹${summary!['remaining']}"),
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
                buildList(pending),
                buildList(partial),
                buildList(completed),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () async {
                await DatabaseHelper().closeTrip(widget.tripId);
                Navigator.pop(context);
              },
              child: const Text("Close Trip"),
            ),
          )
        ],
      ),
    );
  }
}