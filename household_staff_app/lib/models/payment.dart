class Payment {
  final int? id;
  final int employeeId;
  final double amount;
  final String paymentType; // 'salary', 'advance', 'remaining', 'bonus'
  final String paymentDate;
  final String paymentMethod; // 'cash', 'bank', 'upi'
  final String? notes;
  final String createdDate;
  final String? monthYear; // 'YYYY-MM' for salary/advance tracking
  final bool isAdvancePayment; // true for advance, false for regular
  final double? remainingAmount; // for advance payments

  Payment({
    this.id,
    required this.employeeId,
    required this.amount,
    required this.paymentType,
    required this.paymentDate,
    required this.paymentMethod,
    this.notes,
    required this.createdDate,
    this.monthYear,
    this.isAdvancePayment = false,
    this.remainingAmount,
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
      'month_year': monthYear,
      'is_advance_payment': isAdvancePayment ? 1 : 0,
      'remaining_amount': remainingAmount,
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
      monthYear: map['month_year'],
      isAdvancePayment: (map['is_advance_payment'] ?? 0) == 1,
      remainingAmount: map['remaining_amount'],
    );
  }

  // Helper method to get payment type display text
  String get paymentTypeDisplayText {
    switch (paymentType) {
      case 'salary':
        return 'Monthly Salary';
      case 'advance':
        return 'Advance Payment';
      case 'remaining':
        return 'Remaining Payment';
      case 'bonus':
        return 'Bonus';
      default:
        return paymentType;
    }
  }

  // Helper method to get payment method display text
  String get paymentMethodDisplayText {
    switch (paymentMethod) {
      case 'cash':
        return 'Cash';
      case 'bank':
        return 'Bank Transfer';
      case 'upi':
        return 'UPI';
      default:
        return paymentMethod;
    }
  }
}

// Model for monthly payment summary
class MonthlyPaymentSummary {
  final String monthYear;
  final int employeeId;
  final String employeeName;
  final double monthlySalary;
  final double totalAdvancesPaid;
  final double remainingAmount;
  final List<Payment> advances;
  final List<Payment> salaryPayments;
  final bool isFullyPaid;

  MonthlyPaymentSummary({
    required this.monthYear,
    required this.employeeId,
    required this.employeeName,
    required this.monthlySalary,
    required this.totalAdvancesPaid,
    required this.remainingAmount,
    required this.advances,
    required this.salaryPayments,
    required this.isFullyPaid,
  });

  double get totalPaid => totalAdvancesPaid + salaryPayments.fold(0.0, (sum, payment) => sum + payment.amount);
  double get pendingAmount => monthlySalary - totalPaid;
}