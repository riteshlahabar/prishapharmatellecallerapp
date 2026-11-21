class CallLog {
  final int? id;
  final int? telecallerId;
  final int? customerId;
  final String customerName;
  final String callDate;
  final String callTime;
  final String result;
  final String notes;

  CallLog({
    this.id,
    this.telecallerId,
    this.customerId,
    this.customerName = '',
    this.callDate = '',
    this.callTime = '',
    this.result = 'completed',
    this.notes = '',
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['id'] as int?,
      telecallerId: json['telecaller_id'] as int?,
      customerId: json['customer_id'] as int?,
      customerName: json['customer_name'] as String? ?? '',
      callDate: json['call_date'] as String? ?? '',
      callTime: json['call_time'] as String? ?? '',
      result: json['result'] as String? ?? 'completed',
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (telecallerId != null) 'telecaller_id': telecallerId,
      if (customerId != null) 'customer_id': customerId,
      'customer_name': customerName,
      'call_date': callDate,
      'call_time': callTime,
      'result': result,
      'notes': notes,
    };
  }
}
