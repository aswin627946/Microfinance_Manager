class Borrower {
  final int? borrowerId;
  final String name;
  final int status;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final String createdAt;
  final String? updatedAt;
  final int isSynced; // 0 = not synced, 1 = synced

  Borrower({
    this.borrowerId,
    required this.name,
    required this.status,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.updatedAt,
    this.isSynced = 0,
  });

  // Convert object → Map
  Map<String, dynamic> toMap() {
    return {
      'borrower_id': borrowerId,
      'name': name,
      'status': status,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'isSynced': isSynced,
    };
  }

  // Convert Map → object
  factory Borrower.fromMap(Map<String, dynamic> map) {
    return Borrower(
      borrowerId: map['borrower_id'],
      name: map['name'],
      status: map['status'] ?? 0,
      phone: map['phone'],
      address: map['address'],
      latitude: map['latitude'] != null ? map['latitude'] * 1.0 : null,
      longitude: map['longitude'] != null ? map['longitude'] * 1.0 : null,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      isSynced: map['isSynced'] ?? 0,
    );
  }
}