// screens/components/payment_update_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/booking_model.dart';
import '../models/order_model.dart';

class PaymentUpdateDialog extends StatefulWidget {
  final Booking? booking;
  final Order? order;
  final Function(String paymentStatus, String paymentMethod, String trnNumber) onPaymentUpdate;

  const PaymentUpdateDialog({
    Key? key,
    this.booking,
    this.order,
    required this.onPaymentUpdate,
  }) : super(key: key);

  @override
  State<PaymentUpdateDialog> createState() => _PaymentUpdateDialogState();
}

class _PaymentUpdateDialogState extends State<PaymentUpdateDialog> {
  final TextEditingController _trnController = TextEditingController();
  String _selectedStatus = 'paid';
  String _selectedMethod = 'cash';

  final List<String> _paymentMethods = ['cash', 'card', 'digital', 'check', 'cod', 'wallet'];
  final List<String> _paymentStatuses = ['paid', 'pending', 'failed', 'refunded', 'partial'];

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      _selectedStatus = widget.booking!.paymentStatus;
      _selectedMethod = widget.booking!.paymentMethod;
      _trnController.text = widget.booking!.trnNumber;
    } else if (widget.order != null) {
      _selectedStatus = widget.order!.paymentStatus;
      _selectedMethod = widget.order!.paymentMethod;
    }
  }

  String get _title {
    if (widget.booking != null) {
      return 'Update Booking Payment';
    } else if (widget.order != null) {
      return 'Update Order Payment';
    }
    return 'Update Payment';
  }

  String get _currentPaymentStatus {
    return widget.booking?.paymentStatus ?? widget.order?.paymentStatus ?? 'pending';
  }

  String get _currentPaymentMethod {
    return widget.booking?.paymentMethod ?? widget.order?.paymentMethod ?? 'cash';
  }

  String get _currentTRN {
    return widget.booking?.trnNumber ?? '';
  }

  double get _totalAmount {
    if (widget.booking != null) {
      return widget.booking!.totalAmount;
    } else if (widget.order != null) {
      return widget.order!.totalAmount;
    }
    return 0.0;
  }

  String _formatCurrency(double amount) {
    if (widget.booking != null) {
      return widget.booking!.formatCurrency(amount);
    }
    return 'د.إ${amount.toStringAsFixed(2)}';
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      case 'partial':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'digital':
        return Icons.mobile_friendly;
      case 'check':
        return Icons.receipt;
      case 'cod':
        return Icons.local_shipping;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStatusColor = _getPaymentStatusColor(_currentPaymentStatus);

    return AlertDialog(
      title: Text(
        _title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current Payment Info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: currentStatusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: currentStatusColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getPaymentMethodIcon(_currentPaymentMethod),
                        color: currentStatusColor,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Status',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _currentPaymentStatus.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: currentStatusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Method: ${_currentPaymentMethod.toUpperCase()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (_currentTRN.isNotEmpty)
                    Text(
                      'TRN: $_currentTRN',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Amount Info
            Card(
              child: ListTile(
                leading: Icon(Icons.attach_money, color: Colors.green),
                title: Text('Total Amount'),
                subtitle: Text(_formatCurrency(_totalAmount)),
              ),
            ),
            SizedBox(height: 16),

            // Payment Method Selection
            Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _paymentMethods.map((method) {
                final isSelected = _selectedMethod == method;
                return ChoiceChip(
                  label: Text(
                    method.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: _getPaymentStatusColor(_selectedStatus),
                  backgroundColor: Colors.grey[200],
                  onSelected: (selected) {
                    setState(() {
                      _selectedMethod = method;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16),

            // Payment Status Selection
            Text(
              'Payment Status',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _paymentStatuses.map((status) {
                final isSelected = _selectedStatus == status;
                return ChoiceChip(
                  label: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: _getPaymentStatusColor(status),
                  backgroundColor: Colors.grey[200],
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16),

            // Transaction Number
            TextField(
              controller: _trnController,
              decoration: InputDecoration(
                labelText: 'Transaction Number (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Enter transaction/reference number',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'For card/digital payments, enter the transaction reference number',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),

            // Additional fields for partial payments
            if (_selectedStatus == 'partial')
              Column(
                children: [
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Paid Amount',
                      border: OutlineInputBorder(),
                      hintText: 'Enter amount paid',
                      prefixText: 'د.إ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Remaining: ${_formatCurrency(_totalAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onPaymentUpdate(
              _selectedStatus,
              _selectedMethod,
              _trnController.text.trim(),
            );
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _getPaymentStatusColor(_selectedStatus),
          ),
          child: Text(
            'Update Payment',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}