class Payment{
  final int paymentId;
  final int loanId;
  final int borrowerId;
  final int tripId;
  final double amountPaid;
  final String paymentDate;
  final String paymentType;
  final String createdAt;
  final int isSynced; // 0 = not synced, 1 = synced

  Payment({
    required this.paymentId,
    required this.loanId,
    required this.borrowerId,
    required this.tripId,
    required this.amountPaid,
    required this.paymentDate,
    required this.paymentType,
    required this.createdAt,
    required this.isSynced,
  });

  Map<String, dynamic> toMap() {
    return {
      'payment_id': paymentId,
      'loan_id': loanId,
      'borrower_id': borrowerId,
      'trip_id': tripId,
      'amount_paid': amountPaid ,
      'payment_date': paymentDate,
      'payment_type': paymentType,
      'created_at': createdAt,
      'isSynced': isSynced,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      paymentId: map['payment_id'],
      loanId: map['loan_id'],
      borrowerId: map['borrower_id'],
      tripId: map['trip_id'],
      amountPaid: map['amount_paid'] != null ? map['amount_paid'] * 1.0 : null,
      paymentDate: map['payment_date'],
      paymentType: map['payment_type'],
      createdAt: map['created_at'],
      isSynced: map['isSynced'] ?? 0,
    );
  }
}