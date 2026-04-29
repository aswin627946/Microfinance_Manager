class Trip{
  final int tripId;
  final String tripDate;
  final int? agentId;
  final int status;
  final String createdAt;

  Trip({
    required this.tripId,
    required this.tripDate,
    this.agentId,
    this.status = 1,
    required this.createdAt,
  });

  Map<String,dynamic> toMap(){
    return {
      'trip_id': tripId,
      'trip_date': tripDate,
      'agent_id': agentId,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory Trip.fromMap(Map<String,dynamic> map){
    return Trip(
      tripId: map['trip_id'],
      tripDate: map['trip_date'],
      agentId: map['agent_id'],
      status: map['status'] ?? 0,
      createdAt: map['created_at'],
    );
  }
}