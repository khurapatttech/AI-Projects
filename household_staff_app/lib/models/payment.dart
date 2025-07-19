class Payment {
  final int? id;
  final int employeeId;
  final double amount;
  final String paymentType;
  final String paymentDate;
  final String paymentMethod;
  final String? notes;
  final String createdDate;

  Payment({
    this.id,
    required this.employeeId,
    required this.amount,
    required this.paymentType,
    required this.paymentDate,
    required this.paymentMethod,
    this.notes,
    required this.createdDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'amount': amount,
      'payment_type': paymentType,
      'payment_date': paymentDate,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_date': createdDate,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      employeeId: map['employee_id'],
      amount: map['amount'],
      paymentType: map['payment_type'],
      paymentDate: map['payment_date'],
      paymentMethod: map['payment_method'],
      notes: map['notes'],
      createdDate: map['created_date'],
    );
  }
} 