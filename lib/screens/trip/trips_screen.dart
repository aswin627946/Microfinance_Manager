import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import 'trips_detail_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  List<Map<String, dynamic>> trips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTrips();
  }

  Future<void> loadTrips() async {
    final db = await DatabaseHelper().database;

    final result = await db.query(
      'trips',
      orderBy: 'trip_date DESC',
    );

    setState(() {
      trips = result;
      isLoading = false;
    });
  }

  // 🚗 Start New Trip
  Future<void> startTrip() async {
    int tripId = await DatabaseHelper().createTrip();

    await loadTrips();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailScreen(tripId: tripId),
      ),
    );
  }

  // 📅 Format Date
  String formatDate(String date) {
    final d = DateTime.parse(date);
    return "${d.day}/${d.month}/${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trip")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trips.isEmpty
              ? const Center(child: Text("No trips yet"))
              : ListView.builder(
                  itemCount: trips.length,
                  itemBuilder: (_, i) {
                    final trip = trips[i];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text("Trip #${trip['trip_id']}"),
                        subtitle: Text(
                            "Date: ${formatDate(trip['trip_date'])}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              trip['status'] == 1 ? "Completed" : "Active",
                              style: TextStyle(
                                color: trip['status'] == 1 ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TripDetailScreen(
                                tripId: trip['trip_id'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

      // ➕ Floating Button
      floatingActionButton: FloatingActionButton(
        onPressed: startTrip,
        child: const Icon(Icons.add),
      ),
    );
  }
}