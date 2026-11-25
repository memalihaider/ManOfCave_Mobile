import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../constants/booking_status.dart';

enum BookingStatus {
  upcoming,
  inProgress,
  closed,
  cancelled
}

class Booking {
  final String id;
  final String bookingNumber;
  final String bookingDate;
  final String bookingTime;

  // Customer details
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;

  // Booking details
  final String date;
  final String time;
  final String timeSlot;
  final double totalAmount;
  final String status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pointsAwarded;
  final String source;
  final String createdBy;

  // Payment details
  final double subtotal;
  final double serviceCharges;
  final double tax;
  final double taxAmount;
  final double discount;
  final double discountAmount;
  final String discountType;
  final double tip;
  final double totalTips;
  final double serviceTip;
  final String paymentMethod;
  final String paymentStatus;
  final Map<String, dynamic> paymentAmounts;
  final String trnNumber;
  final String cardLast4Digits;

  // Service details
  final String serviceId;
  final String serviceName;
  final double servicePrice;
  final int serviceDuration;
  final String serviceCategory;
  final String serviceCategoryId;
  final List<String> services;
  final int totalDuration;

  // Staff details
  final String staffId;
  final String staffName;
  final String staffRole;
  final List<Map<String, dynamic>> teamMembers;

  // Branch details
  final String branch;
  final String branchId;
  final List<String> branches;
  final List<String> branchNames;
  final String userBranchId;
  final String userBranchName;
  final String userRole;

  // Product details
  final List<dynamic> products;
  final double productsTotal;

  Booking({
    required this.id,
    required this.bookingNumber,
    required this.bookingDate,
    required this.bookingTime,

    // Customer details
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,

    // Booking details
    required this.date,
    required this.time,
    required this.timeSlot,
    required this.totalAmount,
    required this.status,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.pointsAwarded = false,
    this.source = 'admin_panel',
    this.createdBy = '',

    // Payment details
    required this.subtotal,
    required this.serviceCharges,
    required this.tax,
    required this.taxAmount,
    this.discount = 0,
    this.discountAmount = 0,
    this.discountType = 'fixed',
    this.tip = 0,
    this.totalTips = 0,
    this.serviceTip = 0,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    this.paymentAmounts = const {},
    this.trnNumber = '',
    this.cardLast4Digits = '',

    // Service details
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDuration,
    required this.serviceCategory,
    required this.serviceCategoryId,
    this.services = const [],
    required this.totalDuration,

    // Staff details
    required this.staffId,
    required this.staffName,
    required this.staffRole,
    this.teamMembers = const [],

    // Branch details
    required this.branch,
    required this.branchId,
    this.branches = const [],
    this.branchNames = const [],
    required this.userBranchId,
    required this.userBranchName,
    this.userRole = '',

    // Product details
    this.products = const [],
    this.productsTotal = 0,
  });

  // Factory constructor to create Booking from Firestore Document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Booking(
      id: doc.id,
      bookingNumber: data['bookingNumber'] ?? '',
      bookingDate: data['bookingDate'] ?? '',
      bookingTime: data['bookingTime'] ?? '',

      // Customer details
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',

      // Booking details
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: BookingStatusValues.normalize(data['status']?.toString()),
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      pointsAwarded: data['pointsAwarded'] ?? false,
      source: data['source'] ?? 'admin_panel',
      createdBy: data['createdBy'] ?? '',

      // Payment details
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      serviceCharges: (data['serviceCharges'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      discountAmount: (data['discountAmount'] ?? 0).toDouble(),
      discountType: data['discountType'] ?? 'fixed',
      tip: (data['tip'] ?? 0).toDouble(),
      totalTips: (data['totalTips'] ?? 0).toDouble(),
      serviceTip: (data['serviceTip'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'cash',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentAmounts: Map<String, dynamic>.from(data['paymentAmounts'] ?? {}),
      trnNumber: data['trnNumber'] ?? '',
      cardLast4Digits: data['cardLast4Digits'] ?? '',

      // Service details
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      servicePrice: (data['servicePrice'] ?? 0).toDouble(),
      serviceDuration: (data['serviceDuration'] ?? 0).toInt(),
      serviceCategory: data['serviceCategory'] ?? '',
      serviceCategoryId: data['serviceCategoryId'] ?? '',
      services: List<String>.from(data['services'] ?? []),
      totalDuration: (data['totalDuration'] ?? 0).toInt(),

      // Staff details
      staffId: data['staffId'] ?? '',
      staffName: data['staffName'] ?? '',
      staffRole: data['staffRole'] ?? '',
      teamMembers: List<Map<String, dynamic>>.from(data['teamMembers'] ?? []),

      // Branch details
      branch: data['branch'] ?? '',
      branchId: data['branchId'] ?? '',
      branches: List<String>.from(data['branches'] ?? []),
      branchNames: List<String>.from(data['branchNames'] ?? []),
      userBranchId: data['userBranchId'] ?? '',
      userBranchName: data['userBranchName'] ?? '',
      userRole: data['userRole'] ?? '',

      // Product details
      products: List<dynamic>.from(data['products'] ?? []),
      productsTotal: (data['productsTotal'] ?? 0).toDouble(),
    );
  }

  // Convert Booking to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'bookingNumber': bookingNumber,
      'bookingDate': bookingDate,
      'bookingTime': bookingTime,

      // Customer details
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,

      // Booking details
      'date': date,
      'time': time,
      'timeSlot': timeSlot,
      'totalAmount': totalAmount,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'pointsAwarded': pointsAwarded,
      'source': source,
      'createdBy': createdBy,

      // Payment details
      'subtotal': subtotal,
      'serviceCharges': serviceCharges,
      'tax': tax,
      'taxAmount': taxAmount,
      'discount': discount,
      'discountAmount': discountAmount,
      'discountType': discountType,
      'tip': tip,
      'totalTips': totalTips,
      'serviceTip': serviceTip,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentAmounts': paymentAmounts,
      'trnNumber': trnNumber,
      'cardLast4Digits': cardLast4Digits,

      // Service details
      'serviceId': serviceId,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'serviceDuration': serviceDuration,
      'serviceCategory': serviceCategory,
      'serviceCategoryId': serviceCategoryId,
      'services': services,
      'totalDuration': totalDuration,

      // Staff details
      'staffId': staffId,
      'staffName': staffName,
      'staffRole': staffRole,
      'teamMembers': teamMembers,

      // Branch details
      'branch': branch,
      'branchId': branchId,
      'branches': branches,
      'branchNames': branchNames,
      'userBranchId': userBranchId,
      'userBranchName': userBranchName,
      'userRole': userRole,

      // Product details
      'products': products,
      'productsTotal': productsTotal,
    };
  }

  // Helper methods
  bool get isPending => BookingStatusValues.normalize(status) == BookingStatusValues.upcoming;
  bool get isConfirmed => BookingStatusValues.normalize(status) == BookingStatusValues.upcoming;
  bool get isInProgress => BookingStatusValues.normalize(status) == BookingStatusValues.inProgress;
  bool get isCompleted => BookingStatusValues.normalize(status) == BookingStatusValues.closed;
  bool get isCancelled => BookingStatusValues.normalize(status) == BookingStatusValues.cancelled;

  DateTime get serviceDateTime {
    try {
      final dateParts = date.split('-');
      final timeParts = timeSlot.split(':');
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  bool get isToday {
    final today = DateTime.now();
    return date == '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return serviceDateTime.isAfter(now);
  }

  bool get isPast {
    final now = DateTime.now();
    return serviceDateTime.isBefore(now);
  }

  // Status color helper
  Color get statusColor {
    switch (status) {
      case 'upcoming':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'in-progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Status icon helper
  IconData get statusIcon {
    switch (status) {
      case 'upcoming':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle_outline;
      case 'in-progress':
        return Icons.access_time;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // Payment method icon helper
  IconData get paymentMethodIcon {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'digital':
        return Icons.mobile_friendly;
      case 'check':
        return Icons.receipt;
      default:
        return Icons.payment;
    }
  }

  // Payment status color helper
  Color get paymentStatusColor {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Format currency
  String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} ${AppStrings.appCurreny}';
  }

  // Get total before tax
  double get totalBeforeTax {
    return subtotal + serviceCharges + serviceTip + tip + productsTotal;
  }

  // Get grand total
  double get grandTotal {
    return totalBeforeTax + taxAmount - discountAmount;
  }

  // Get service total
  double get serviceTotal {
    return subtotal;
  }

  // Get formatted team members
  String get formattedTeamMembers {
    if (teamMembers.isEmpty) return 'No team members';
    return teamMembers.map((member) => member['name'] ?? '').join(', ');
  }

  // Get formatted services
  String get formattedServices {
    if (services.isEmpty) return serviceName;
    return services.join(', ');
  }

  // Get duration formatted
  String get durationFormatted {
    final hours = (totalDuration / 60).floor();
    final minutes = totalDuration % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  // Get formatted date for display
  String get formattedDate {
    try {
      final dateParts = date.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final dateTime = DateTime(year, month, day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      if (dateTime == today) return 'Today';
      if (dateTime == yesterday) return 'Yesterday';

      return '${dateParts[2]}/${dateParts[1]}';
    } catch (e) {
      return date;
    }
  }

  // Get formatted time for display
  String get formattedTime {
    try {
      final timeParts = timeSlot.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (hour > 12) {
        return '${hour - 12}:${minute.toString().padLeft(2, '0')} PM';
      } else if (hour == 12) {
        return '12:${minute.toString().padLeft(2, '0')} PM';
      } else if (hour == 0) {
        return '12:${minute.toString().padLeft(2, '0')} AM';
      } else {
        return '$hour:${minute.toString().padLeft(2, '0')} AM';
      }
    } catch (e) {
      return time;
    }
  }

  // Copy with method for updates
  Booking copyWith({
    String? status,
    String? notes,
    DateTime? updatedAt,
    bool? pointsAwarded,
    String? paymentStatus,
    String? staffId,
    String? staffName,
    String? staffRole,
    List<Map<String, dynamic>>? teamMembers,
    double? tip,
    double? serviceTip,
    double? totalTips,
  }) {
    return Booking(
      id: id,
      bookingNumber: bookingNumber,
      bookingDate: bookingDate,
      bookingTime: bookingTime,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      date: date,
      time: time,
      timeSlot: timeSlot,
      totalAmount: totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      source: source,
      createdBy: createdBy,
      subtotal: subtotal,
      serviceCharges: serviceCharges,
      tax: tax,
      taxAmount: taxAmount,
      discount: discount,
      discountAmount: discountAmount,
      discountType: discountType,
      tip: tip ?? this.tip,
      totalTips: totalTips ?? this.totalTips,
      serviceTip: serviceTip ?? this.serviceTip,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentAmounts: paymentAmounts,
      trnNumber: trnNumber,
      cardLast4Digits: cardLast4Digits,
      serviceId: serviceId,
      serviceName: serviceName,
      servicePrice: servicePrice,
      serviceDuration: serviceDuration,
      serviceCategory: serviceCategory,
      serviceCategoryId: serviceCategoryId,
      services: services,
      totalDuration: totalDuration,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      staffRole: staffRole ?? this.staffRole,
      teamMembers: teamMembers ?? this.teamMembers,
      branch: branch,
      branchId: branchId,
      branches: branches,
      branchNames: branchNames,
      userBranchId: userBranchId,
      userBranchName: userBranchName,
      userRole: userRole,
      products: products,
      productsTotal: productsTotal,
    );
  }

  // Get booking summary for quick display
  Map<String, dynamic> get summary {
    return {
      'id': id,
      'bookingNumber': bookingNumber,
      'customerName': customerName,
      'serviceName': serviceName,
      'staffName': staffName,
      'date': formattedDate,
      'time': formattedTime,
      'status': status,
      'totalAmount': totalAmount,
      'branch': branch,
      'paymentStatus': paymentStatus,
    };
  }
}