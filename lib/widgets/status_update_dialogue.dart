// Update the StatusUpdateDialog to support both bookings and orders
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

import '../models/booking_model.dart';
import '../models/order_model.dart';

class StatusUpdateDialog extends StatefulWidget {
  final Booking? booking;
  final Order? order;
  final Function(String status, String notes) onStatusUpdate;

  const StatusUpdateDialog({
    Key? key,
    this.booking,
    this.order,
    required this.onStatusUpdate,
  }) : super(key: key);

  @override
  State<StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<StatusUpdateDialog> {
  final TextEditingController _notesController = TextEditingController();
  String _selectedStatus = 'confirmed';

  List<Map<String, dynamic>> get _statusOptions {
    if (widget.booking != null) {
      return [
        {'value': 'confirmed', 'label': '✅ Confirm', 'color': Colors.green},
        {'value': 'in-progress', 'label': '⏳ In Progress', 'color': Colors.orange},
        {'value': 'completed', 'label': '✓ Complete', 'color': Colors.blue},
        {'value': 'cancelled', 'label': '❌ Cancel', 'color': Colors.red},
      ];
    } else if (widget.order != null) {
      return [
        {'value': 'confirmed', 'label': '✅ Confirm', 'color': Colors.green},
        {'value': 'processing', 'label': '⚙️ Processing', 'color': Colors.orange},
        {'value': 'shipped', 'label': '🚚 Shipped', 'color': Colors.blue},
        {'value': 'delivered', 'label': '✓ Delivered', 'color': Colors.green},
        {'value': 'completed', 'label': '✓ Completed', 'color': Colors.green},
        {'value': 'cancelled', 'label': '❌ Cancel', 'color': Colors.red},
      ];
    }
    return [];
  }

  String get _currentStatus {
    return widget.booking?.status ?? widget.order?.status ?? '';
  }

  String get _title {
    return widget.booking != null ? 'Update Booking Status' : 'Update Order Status';
  }

  @override
  void initState() {
    super.initState();
    _selectedStatus = _currentStatus;
    _notesController.text = widget.booking?.notes ?? widget.order?.orderNotes ?? '';
  }

  @override
  Widget build(BuildContext context) {
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
            // Current Status
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(_currentStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getStatusColor(_currentStatus)),
              ),
              child: Row(
                children: [
                  Icon(_getStatusIcon(_currentStatus), color: _getStatusColor(_currentStatus)),
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
                          _currentStatus.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(_currentStatus),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Status Options
            Text(
              'Select New Status',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            ..._statusOptions.map((option) {
              final isCurrent = _currentStatus == option['value'];
              final isSelected = _selectedStatus == option['value'];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 4),
                color: isSelected ? option['color'].withOpacity(0.1) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? option['color']! : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    _getStatusIcon(option['value']),
                    color: option['color'],
                  ),
                  title: Text(
                    option['label'].substring(2),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? option['color'] : Colors.black,
                    ),
                  ),
                  trailing: isCurrent
                      ? Chip(
                    label: Text('Current'),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(fontSize: 10),
                  )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedStatus = option['value'];
                    });
                  },
                ),
              );
            }).toList(),
            SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Add Notes (Optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onStatusUpdate(_selectedStatus, _notesController.text);
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _getStatusColor(_selectedStatus),
          ),
          child: Text(
            'Update Status',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
      case 'in-progress':
        return Colors.purple;
      case 'shipped':
        return Colors.blueAccent;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'processing':
      case 'in-progress':
        return Icons.rotate_right;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}