class Loan {
  final int loanId;
  final int borrowerId;
  final String createdBy;
  final double principalAmount;
  final double weeklyAmount;
  final int totalWeeks;
  final String startDate;
  final String status; // active, closed, defaulted
  final String createdAt;
  final int isSynced; // 0 = not synced, 1 = synced

  Loan({
    required this.loanId,
    required this.borrowerId,
    required this.createdBy,
    required this.principalAmount,
    required this.weeklyAmount,
    required this.totalWeeks,
    required this.startDate,
    this.status = 'active',
    required this.createdAt,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'loan_id': loanId,
      'borrower_id': borrowerId,
      'created_by': createdBy,
      'principal_amount': principalAmount,
      'weekly_amount': weeklyAmount,
      'total_weeks': totalWeeks,
      'start_date': startDate,
      'status': status,
      'created_at': createdAt,
      'isSynced': isSynced,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      loanId: map['loan_id'],
      borrowerId: map['borrower_id'],
      createdBy: map['created_by'],
      principalAmount: map['principal_amount'],
      weeklyAmount: map['weekly_amount'],
      totalWeeks: map['total_weeks'],
      startDate: map['start_date'],
      status: map['status'],
      createdAt: map['created_at'],
      isSynced: map['isSynced'] ?? 0,
    );
  }
}