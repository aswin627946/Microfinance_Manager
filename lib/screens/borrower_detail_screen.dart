import 'package:flutter/material.dart';
import '../models/borrower_model.dart';
import '../models/loan_model.dart';
import '../services/database_helper.dart';

class BorrowerDetailScreen extends StatelessWidget {
  final Borrower borrower;

  const BorrowerDetailScreen({super.key, required this.borrower});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrower Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            borrower.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Chip(
                            label: Text(
                              borrower.status == 1 ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor:
                                borrower.status == 1 ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: #${borrower.borrowerId}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Contact Information Section
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.phone,
                label: 'Phone',
                value: borrower.phone,
              ),
              _buildInfoCard(
                icon: Icons.location_on,
                label: 'Address',
                value: borrower.address,
              ),
              const SizedBox(height: 20),

              // Location Information Section
              const Text(
                'Location Coordinates',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSmallInfoCard(
                      icon: Icons.location_on,
                      label: 'Latitude',
                      value: borrower.latitude.toStringAsFixed(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallInfoCard(
                      icon: Icons.location_on,
                      label: 'Longitude',
                      value: borrower.longitude.toStringAsFixed(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Timeline Section
              const Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.calendar_today,
                label: 'Created At',
                value: _formatDate(borrower.createdAt),
              ),
              if (borrower.updatedAt != null)
                _buildInfoCard(
                  icon: Icons.update,
                  label: 'Last Updated',
                  value: _formatDate(borrower.updatedAt!),
                ),
              const SizedBox(height: 20),

              // // Sync Status Section
              // const Text(
              //   'Sync Status',
              //   style: TextStyle(
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 12),
              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: borrower.isSynced == 1
              //         ? Colors.green.withOpacity(0.1)
              //         : Colors.orange.withOpacity(0.1),
              //     borderRadius: BorderRadius.circular(8),
              //     border: Border.all(
              //       color: borrower.isSynced == 1 ? Colors.green : Colors.orange,
              //     ),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(
              //         borrower.isSynced == 1
              //             ? Icons.cloud_done
              //             : Icons.cloud_off,
              //         color: borrower.isSynced == 1 ? Colors.green : Colors.orange,
              //         size: 28,
              //       ),
              //       const SizedBox(width: 12),
              //       Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             borrower.isSynced == 1
              //                 ? 'Synced with Server'
              //                 : 'Pending Sync',
              //             style: const TextStyle(
              //               fontSize: 16,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //           Text(
              //             borrower.isSynced == 1
              //                 ? 'Data is up-to-date'
              //                 : 'Waiting to sync with server',
              //             style: const TextStyle(
              //               fontSize: 12,
              //               color: Colors.grey,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 30),

              // Related Loans Section
              const Text(
                'Related Loans',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Loan>>(
                future: DatabaseHelper().getLoansByBorrowerId(borrower.borrowerId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No loans associated with this borrower',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  }

                  final loans = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: loans.length,
                    itemBuilder: (context, index) {
                      final loan = loans[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Loan #${loan.loanId}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(loan.status),
                                    backgroundColor:
                                        loan.status == 'Active'
                                            ? Colors.green
                                            : Colors.orange,
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Principal:',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    '\$${loan.principalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Weekly Amount:',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    '\$${loan.weeklyAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateString;
    }
  }
}
