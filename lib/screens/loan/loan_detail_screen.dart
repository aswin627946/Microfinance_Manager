import 'package:flutter/material.dart';
import '../../models/loan_model.dart';
import '../../models/payments_model.dart';
import '../../models/borrower_model.dart';
import '../../services/database_helper.dart';
import '../borrower/borrower_detail_screen.dart';

class LoanDetailScreen extends StatelessWidget {
  final Loan loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final weeklyAmount =
        (loan.weeklyAmount).toStringAsFixed(2);
    final totalAmount =
        (loan.weeklyAmount * loan.totalWeeks).toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              FutureBuilder<Borrower?>(
                future: _getBorrower(),
                builder: (context, snapshot) {
                  final Borrower borrower = snapshot.data ?? Borrower(  
                    borrowerId: -1,
                    name: "Unknown Borrower",
                    status: 0,
                    phone: "9999999999",
                    address: "123 Main St",
                    latitude: 0.0,
                    longitude: 0.0,
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
                    child: Card(                    elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '# ${loan.loanId}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Borrower: ${borrower.name}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Chip(
                                  label: Text(
                                    loan.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: _getStatusColor(loan.status),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Loan Amount Section
              const Text(
                'Loan Amount Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildAmountCard(
                      label: 'Principal Amount',
                      amount: loan.principalAmount.toStringAsFixed(0),
                      icon: Icons.attach_money,
                      color: Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildAmountCard(
                      label: 'Weekly Amount',
                      amount: '₹$weeklyAmount',
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAmountCard(
                      label: 'Total Amount',
                      amount: '₹$totalAmount',
                      icon: Icons.summarize,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Loan Details Section
              const Text(
                'Loan Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.person,
                label: 'Created By',
                value: loan.createdBy,
              ),
              _buildInfoCard(
                icon: Icons.calendar_today,
                label: 'Created At',
                value: _formatDate(loan.createdAt),
              ),
              const SizedBox(height: 20),

              // Sync Status Section
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
              //     color: loan.isSynced == 1
              //         ? Colors.green.withOpacity(0.1)
              //         : Colors.orange.withOpacity(0.1),
              //     borderRadius: BorderRadius.circular(8),
              //     border: Border.all(
              //       color: loan.isSynced == 1 ? Colors.green : Colors.orange,
              //     ),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(
              //         loan.isSynced == 1 ? Icons.cloud_done : Icons.cloud_off,
              //         color:
              //             loan.isSynced == 1 ? Colors.green : Colors.orange,
              //         size: 28,
              //       ),
              //       const SizedBox(width: 12),
              //       Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             loan.isSynced == 1
              //                 ? 'Synced with Server'
              //                 : 'Pending Sync',
              //             style: const TextStyle(
              //               fontSize: 16,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //           Text(
              //             loan.isSynced == 1
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

              // Summary Card
              // Card(
              //   color: Colors.blue.withOpacity(0.1),
              //   child: Padding(
              //     padding: const EdgeInsets.all(16.0),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         const Text(
              //           'Summary',
              //           style: TextStyle(
              //             fontSize: 16,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //         const SizedBox(height: 12),
              //         Row(
              //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //           children: [
              //             const Text('Principal:'),
              //             Text(
              //               '\$${loan.principalAmount.toStringAsFixed(2)}',
              //               style: const TextStyle(fontWeight: FontWeight.bold),
              //             ),
              //           ],
              //         ),
              //         const SizedBox(height: 8),
              //         Row(
              //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //           children: [
              //             const Text('Interest:'),
              //             Text(
              //               '\$${loan.weeklyAmount.toStringAsFixed(2)} per week',
              //               style: const TextStyle(fontWeight: FontWeight.bold),
              //             ),
              //           ],
              //         ),
              //         const Divider(),
              //         Row(
              //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //           children: [
              //             const Text(
              //               'Total Payable:',
              //               style: TextStyle(fontWeight: FontWeight.bold),
              //             ),
              //             Text(
              //               '\$$totalAmount',
              //               style: const TextStyle(
              //                 fontWeight: FontWeight.bold,
              //                 fontSize: 16,
              //                 color: Colors.green,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 30),

              // Related Payments Section
              const Text(
                'Payment History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Payment>>(
                future: DatabaseHelper().getPaymentsByLoanId(loan.loanId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No payments recorded for this loan',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  }

                  final payments = snapshot.data!;
                  double totalPaid = 0;
                  for (var payment in payments) {
                    totalPaid += payment.amountPaid;
                  }

                  return Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];
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
                                        'Payment #${payment.paymentId}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Chip(
                                        label: Text(payment.paymentType),
                                        backgroundColor: Colors.blue,
                                        labelStyle: const TextStyle(
                                            color: Colors.white),
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
                                        'Amount:',
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                      Text(
                                        '₹${payment.amountPaid.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Date:',
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                      Text(
                                        payment.paymentDate,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Paid:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹$totalPaid',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

  Widget _buildAmountCard({
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
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
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case '1':
        return Colors.green;
      case 'closed':
        return Colors.blue;
      case 'defaulted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<Borrower?> _getBorrower() async {
    final borrower = await DatabaseHelper().getBorrowerById(loan.borrowerId);
    return borrower;
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
