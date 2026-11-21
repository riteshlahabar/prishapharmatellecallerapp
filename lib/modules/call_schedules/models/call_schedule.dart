class CallSchedule {
  final int? id;
  final int? telecallerId;
  final int? customerId;
  final String customerName;
  final String scheduledDate;
  final String scheduledTime;
  final String status;
  final String notes;

  CallSchedule({
    this.id,
    this.telecallerId,
    this.customerId,
    this.customerName = '',
    this.scheduledDate = '',
    this.scheduledTime = '',
    this.status = 'pending',
    this.notes = '',
  });

  factory CallSchedule.fromJson(Map<String, dynamic> json) {
    return CallSchedule(
      id: json['id'] as int?,
      telecallerId: json['telecaller_id'] as int?,
      customerId: json['customer_id'] as int?,
      customerName: json['customer_name'] as String? ?? '',
      scheduledDate: json['scheduled_date'] as String? ?? '',
      scheduledTime: json['scheduled_time'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (telecallerId != null) 'telecaller_id': telecallerId,
      if (customerId != null) 'customer_id': customerId,
      'customer_name': customerName,
      'scheduled_date': scheduledDate,
      'scheduled_time': scheduledTime,
      'status': status,
      'notes': notes,
    };
  }

  CallSchedule copyWith({
    int? id,
    int? telecallerId,
    int? customerId,
    String? customerName,
    String? scheduledDate,
    String? scheduledTime,
    String? status,
    String? notes,
  }) {
    return CallSchedule(
      id: id ?? this.id,
      telecallerId: telecallerId ?? this.telecallerId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
