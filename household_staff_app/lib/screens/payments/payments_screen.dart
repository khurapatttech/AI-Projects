import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/payment.dart';
import '../../services/database_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Employee> _employees = [];
  List<MonthlyPaymentSummary> _paymentSummaries = [];
  bool _isLoading = false;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final employees = await DatabaseService().getAllEmployees();
      final summaries = await DatabaseService().getMonthlyPaymentSummaries();
      
      setState(() {
        _employees = employees.where((e) => e.activeStatus).toList();
        _paymentSummaries = summaries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Payment Management'),
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.payment), text: 'Advance'),
            Tab(icon: Icon(Icons.account_balance), text: 'Monthly'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAdvancePaymentTab(),
                _buildMonthlyPaymentTab(),
                _buildPaymentHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildAdvancePaymentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Make Advance Payment',
            'Pay advance salary to staff members',
            Icons.payment,
          ),
          const SizedBox(height: 16),
          _buildAdvancePaymentCard(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Recent Advances',
            'Latest advance payments made',
            Icons.history,
          ),
          const SizedBox(height: 16),
          _buildRecentAdvancesCard(),
        ],
      ),
    );
  }

  Widget _buildMonthlyPaymentTab() {
    // Get the selected month summaries and filter by employee joining date
    final selectedMonthSummaries = _paymentSummaries
        .where((s) => s.monthYear == _selectedMonth)
        .where((s) {
          // Check if employee was working in the selected month
          final employee = _employees.firstWhere((e) => e.id == s.employeeId);
          final joiningDate = DateTime.parse(employee.joiningDate);
          final selectedMonthDate = DateTime(
            int.parse(_selectedMonth.split('-')[0]),
            int.parse(_selectedMonth.split('-')[1]),
          );
          
          // Employee should be included if they joined before or during the selected month
          return joiningDate.isBefore(selectedMonthDate) || 
                 (joiningDate.year == selectedMonthDate.year && 
                  joiningDate.month == selectedMonthDate.month);
        })
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Monthly Payment Summary',
            'Select month to view payment details',
            Icons.calendar_today,
          ),
          const SizedBox(height: 16),
          
          // Month selector
          _buildMonthSelector(),
          const SizedBox(height: 20),
          
          if (selectedMonthSummaries.isEmpty)
            _buildEmptyState('No payment data for ${DateFormat('MMMM yyyy').format(DateTime(
              int.parse(_selectedMonth.split('-')[0]),
              int.parse(_selectedMonth.split('-')[1]),
            ))}')
          else
            ...selectedMonthSummaries.map((summary) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMonthlySummaryCard(summary),
            )),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    // Generate last 6 months
    final now = DateTime.now();
    final months = <String>[];
    
    for (int i = 0; i < 6; i++) {
      final monthDate = DateTime(now.year, now.month - i);
      final monthString = DateFormat('yyyy-MM').format(monthDate);
      months.add(monthString);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: const Color(0xFF6366F1), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Select Month',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];
                final monthDate = DateTime(
                  int.parse(month.split('-')[0]),
                  int.parse(month.split('-')[1]),
                );
                final isSelected = month == _selectedMonth;
                final isCurrentMonth = month == DateFormat('yyyy-MM').format(now);
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMonth = month;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF6366F1)
                            : isCurrentMonth 
                                ? Colors.blue.shade50
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF6366F1)
                              : isCurrentMonth 
                                  ? Colors.blue.shade200
                                  : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMM').format(monthDate),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                  ? Colors.white
                                  : isCurrentMonth 
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            DateFormat('yyyy').format(monthDate),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected 
                                  ? Colors.white70
                                  : isCurrentMonth 
                                      ? Colors.blue.shade600
                                      : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryTab() {
    // Get all payments from all employees and sort by date
    final allPayments = _paymentSummaries
        .expand((summary) => [
              ...summary.advances,
              ...summary.salaryPayments,
            ])
        .toList()
        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    // Group payments by date for better organization
    final groupedPayments = <String, List<Payment>>{};
    for (final payment in allPayments) {
      final dateKey = payment.paymentDate;
      if (!groupedPayments.containsKey(dateKey)) {
        groupedPayments[dateKey] = [];
      }
      groupedPayments[dateKey]!.add(payment);
    }

    final sortedDates = groupedPayments.keys.toList()..sort((a, b) => b.compareTo(a));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Payment History',
            'Complete transaction history for all staff',
            Icons.history,
          ),
          const SizedBox(height: 16),
          
          // Summary stats
          _buildHistorySummaryCard(allPayments),
          const SizedBox(height: 20),
          
          if (sortedDates.isEmpty)
            _buildEmptyState('No payment history available')
          else
            ...sortedDates.map((date) {
              final dayPayments = groupedPayments[date]!;
              final dateObj = DateTime.parse(date);
              final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == date;
              final isYesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1))) == date;
              
              String dateLabel;
              if (isToday) {
                dateLabel = 'Today';
              } else if (isYesterday) {
                dateLabel = 'Yesterday';
              } else {
                dateLabel = DateFormat('MMMM dd, yyyy').format(dateObj);
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header with daily total
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '₹${dayPayments.fold<double>(0, (sum, p) => sum + p.amount).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Payments for this date
                  ...dayPayments.map((payment) => _buildTransactionItem(payment)),
                  const SizedBox(height: 16),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHistorySummaryCard(List<Payment> allPayments) {
    final totalAmount = allPayments.fold<double>(0, (sum, p) => sum + p.amount);
    final advanceCount = allPayments.where((p) => p.paymentType == 'advance').length;
    final salaryCount = allPayments.where((p) => p.paymentType == 'salary' || p.paymentType == 'remaining').length;
    final thisMonthPayments = allPayments.where((p) => 
      p.paymentDate.startsWith(DateFormat('yyyy-MM').format(DateTime.now()))
    ).toList();
    final thisMonthTotal = thisMonthPayments.fold<double>(0, (sum, p) => sum + p.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Paid',
                  '₹${totalAmount.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'This Month',
                  '₹${thisMonthTotal.toStringAsFixed(0)}',
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Advances',
                  '$advanceCount payments',
                  Icons.payment,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Salaries',
                  '$salaryCount payments',
                  Icons.account_balance,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Payment payment) {
    final employee = _employees.firstWhere(
      (e) => e.id == payment.employeeId,
      orElse: () => Employee(
        name: 'Unknown Employee',
        age: 0,
        phone: '',
        monthlySalary: 0,
        visitsPerDay: 1,
        offDays: [],
        createdDate: '',
        joiningDate: '',
      ),
    );

    final paymentTypeColor = _getPaymentTypeColor(payment.paymentType);
    final paymentTypeIcon = _getPaymentTypeIcon(payment.paymentType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Payment type icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: paymentTypeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              paymentTypeIcon,
              color: paymentTypeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Payment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      payment.paymentTypeDisplayText,
                      style: TextStyle(
                        fontSize: 12,
                        color: paymentTypeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (payment.paymentMethod.isNotEmpty) ...[
                      Text(
                        ' • ${payment.paymentMethod.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    payment.notes!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Amount and time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${payment.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: paymentTypeColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('HH:mm').format(DateTime.parse(payment.createdDate)),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getPaymentTypeIcon(String paymentType) {
    switch (paymentType) {
      case 'advance':
        return Icons.payment;
      case 'salary':
        return Icons.account_balance;
      case 'remaining':
        return Icons.pending_actions;
      case 'bonus':
        return Icons.card_giftcard;
      default:
        return Icons.payment;
    }
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6366F1),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancePaymentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text(
                'Quick Advance Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAdvancePaymentDialog(),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Make Advance Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAdvancesCard() {
    final recentAdvances = _paymentSummaries
        .expand((s) => s.advances)
        .toList()
        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    
    final displayAdvances = recentAdvances.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Advance Payments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          if (displayAdvances.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No advance payments yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            ...displayAdvances.map((payment) => _buildPaymentListItem(payment)),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard(MonthlyPaymentSummary summary) {
    // Calculate pro-rated salary if employee joined mid-month
    final employee = _employees.firstWhere((e) => e.id == summary.employeeId);
    final joiningDate = DateTime.parse(employee.joiningDate);
    final summaryMonth = DateTime(
      int.parse(summary.monthYear.split('-')[0]),
      int.parse(summary.monthYear.split('-')[1]),
    );
    
    double actualMonthlySalary = summary.monthlySalary;
    bool isProrated = false;
    
    // Check if employee joined mid-month
    if (joiningDate.year == summaryMonth.year && joiningDate.month == summaryMonth.month) {
      final daysInMonth = DateTime(summaryMonth.year, summaryMonth.month + 1, 0).day;
      final workingDays = daysInMonth - joiningDate.day + 1;
      actualMonthlySalary = (summary.monthlySalary / daysInMonth) * workingDays;
      isProrated = true;
    }
    
    final pendingAmount = actualMonthlySalary - summary.totalPaid;
    final isFullyPaid = pendingAmount == 0;
    final isOverpaid = pendingAmount < 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFullyPaid || isOverpaid
              ? Colors.green.shade200 
              : Colors.orange.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                child: Text(
                  summary.employeeName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.employeeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          isProrated 
                              ? 'Pro-rated Salary: ₹${actualMonthlySalary.toStringAsFixed(0)}'
                              : 'Monthly Salary: ₹${summary.monthlySalary.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (isProrated) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Joined on ${DateFormat('MMM dd, yyyy').format(joiningDate)}',
                            child: Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFullyPaid 
                      ? Colors.green.shade100 
                      : isOverpaid 
                          ? Colors.blue.shade100
                          : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isFullyPaid 
                      ? 'Fully Paid' 
                      : isOverpaid 
                          ? 'Overpaid'
                          : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isFullyPaid 
                        ? Colors.green.shade700 
                        : isOverpaid 
                            ? Colors.blue.shade700
                            : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Payment breakdown
          Row(
            children: [
              Expanded(
                child: _buildPaymentStat(
                  'Advance Paid',
                  '₹${summary.totalAdvancesPaid.toStringAsFixed(0)}',
                  Icons.payment,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentStat(
                  'Total Paid',
                  '₹${summary.totalPaid.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentStat(
                  isOverpaid ? 'Overpaid' : 'Pending',
                  '₹${pendingAmount.abs().toStringAsFixed(0)}',
                  isOverpaid ? Icons.trending_up : Icons.pending_actions,
                  isOverpaid ? Colors.blue : Colors.orange,
                ),
              ),
            ],
          ),
          
          // Action button - only show for pending payments
          if (pendingAmount > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRemainingPaymentDialog(summary, actualMonthlySalary),
                icon: const Icon(Icons.payment, size: 18),
                label: Text('Pay Remaining ₹${pendingAmount.toStringAsFixed(0)}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentListItem(Payment payment) {
    final employee = _employees.firstWhere(
      (e) => e.id == payment.employeeId,
      orElse: () => Employee(
        name: 'Unknown',
        age: 0,
        phone: '',
        monthlySalary: 0,
        visitsPerDay: 1,
        offDays: [],
        createdDate: '',
        joiningDate: '',
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getPaymentTypeColor(payment.paymentType),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${employee.name} - ${payment.paymentTypeDisplayText}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(DateTime.parse(payment.paymentDate)),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${payment.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getPaymentTypeColor(payment.paymentType),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPaymentTypeColor(String paymentType) {
    switch (paymentType) {
      case 'advance':
        return Colors.blue.shade600;
      case 'salary':
        return Colors.green.shade600;
      case 'remaining':
        return Colors.orange.shade600;
      case 'bonus':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  void _showAdvancePaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AdvancePaymentDialog(
        employees: _employees,
        onPaymentMade: _loadData,
      ),
    );
  }

  void _showRemainingPaymentDialog(MonthlyPaymentSummary summary, [double? proratedSalary]) {
    showDialog(
      context: context,
      builder: (context) => RemainingPaymentDialog(
        summary: summary,
        proratedSalary: proratedSalary,
        onPaymentMade: _loadData,
      ),
    );
  }
}

// Advance Payment Dialog
class AdvancePaymentDialog extends StatefulWidget {
  final List<Employee> employees;
  final VoidCallback onPaymentMade;

  const AdvancePaymentDialog({
    Key? key,
    required this.employees,
    required this.onPaymentMade,
  }) : super(key: key);

  @override
  State<AdvancePaymentDialog> createState() => _AdvancePaymentDialogState();
}

class _AdvancePaymentDialogState extends State<AdvancePaymentDialog> {
  Employee? _selectedEmployee;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Make Advance Payment'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee selection
              const Text(
                'Select Employee',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Employee>(
                value: _selectedEmployee,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: widget.employees.map((employee) {
                  return DropdownMenuItem(
                    value: employee,
                    child: Text(employee.name),
                  );
                }).toList(),
                onChanged: (employee) {
                  setState(() {
                    _selectedEmployee = employee;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Amount
              const Text(
                'Amount',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              if (_selectedEmployee != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Monthly Salary: ₹${_selectedEmployee!.monthlySalary.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              
              // Payment method
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Notes
              const Text(
                'Notes (Optional)',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _makePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Make Payment'),
        ),
      ],
    );
  }

  Future<void> _makePayment() async {
    if (_selectedEmployee == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final currentMonth = DateFormat('yyyy-MM').format(now);
      
      final payment = Payment(
        employeeId: _selectedEmployee!.id!,
        amount: amount,
        paymentType: 'advance',
        paymentDate: DateFormat('yyyy-MM-dd').format(now),
        paymentMethod: _paymentMethod,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdDate: now.toIso8601String(),
        monthYear: currentMonth,
        isAdvancePayment: true,
      );

      await DatabaseService().insertPayment(payment);
      
      widget.onPaymentMade();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advance payment recorded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

// Remaining Payment Dialog
class RemainingPaymentDialog extends StatefulWidget {
  final MonthlyPaymentSummary summary;
  final double? proratedSalary;
  final VoidCallback onPaymentMade;

  const RemainingPaymentDialog({
    Key? key,
    required this.summary,
    this.proratedSalary,
    required this.onPaymentMade,
  }) : super(key: key);

  @override
  State<RemainingPaymentDialog> createState() => _RemainingPaymentDialogState();
}

class _RemainingPaymentDialogState extends State<RemainingPaymentDialog> {
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final actualSalary = widget.proratedSalary ?? widget.summary.monthlySalary;
    final remainingAmount = actualSalary - widget.summary.totalPaid;
    _amountController = TextEditingController(
      text: remainingAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pay Remaining to ${widget.summary.employeeName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Summary for ${DateFormat('MMMM yyyy').format(DateTime(
                        int.parse(widget.summary.monthYear.split('-')[0]),
                        int.parse(widget.summary.monthYear.split('-')[1]),
                      ))}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (widget.proratedSalary != null) ...[
                      Text('Full Monthly Salary: ₹${widget.summary.monthlySalary.toStringAsFixed(0)}'),
                      Text('Pro-rated Salary: ₹${widget.proratedSalary!.toStringAsFixed(0)}'),
                    ] else ...[
                      Text('Monthly Salary: ₹${widget.summary.monthlySalary.toStringAsFixed(0)}'),
                    ],
                    Text('Advance Paid: ₹${widget.summary.totalAdvancesPaid.toStringAsFixed(0)}'),
                    Text('Remaining: ₹${((widget.proratedSalary ?? widget.summary.monthlySalary) - widget.summary.totalPaid).toStringAsFixed(0)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Amount
              const Text(
                'Amount to Pay',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 16),
              
              // Payment method
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Notes
              const Text(
                'Notes (Optional)',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _makePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Make Payment'),
        ),
      ],
    );
  }

  Future<void> _makePayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      
      final payment = Payment(
        employeeId: widget.summary.employeeId,
        amount: amount,
        paymentType: 'remaining',
        paymentDate: DateFormat('yyyy-MM-dd').format(now),
        paymentMethod: _paymentMethod,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdDate: now.toIso8601String(),
        monthYear: widget.summary.monthYear,
        isAdvancePayment: false,
      );

      await DatabaseService().insertPayment(payment);
      
      widget.onPaymentMade();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remaining payment recorded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
