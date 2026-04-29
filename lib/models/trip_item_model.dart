class TripItem{
  final int tripItemId;
  final int tripId;
  final int loanId;
  final int borrowerId;
  final double expectedAmount;
  final double collectedAmount;
  final String status;
  final String createdAt;

  TripItem({
    required this.tripItemId,
    required this.tripId,
    required this.loanId,
    required this.borrowerId,
    required this.expectedAmount,
    this.collectedAmount = 0,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'trip_item_id': tripItemId,
      'trip_id': tripId,
      'loan_id': loanId,
      'borrower_id': borrowerId,
      'expected_amount': expectedAmount,
      'collected_amount': collectedAmount,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory TripItem.fromMap(Map<String, dynamic> map) {
    return TripItem(
      tripItemId: map['trip_item_id'],
      tripId: map['trip_id'],
      loanId: map['loan_id'],
      borrowerId: map['borrower_id'],
      expectedAmount: map['expected_amount'] * 1.0,
      collectedAmount: map['collected_amount'] * 1.0,
      status: map['status'],
      createdAt: map['created_at'],
    );
  }

}