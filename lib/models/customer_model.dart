// class Customer {
//   final String id;
//   final String name;
//   final String email;
//   final String? phone;
//   final int points;
//   final String status; // active, inactive
//   final double totalSpent;
//   final int totalBookings;
//   final DateTime memberSince;
//   final DateTime? lastVisit;
//   final String avatarInitials;
//
//   Customer({
//     required this.id,
//     required this.name,
//     required this.email,
//     this.phone,
//     required this.points,
//     required this.status,
//     required this.totalSpent,
//     required this.totalBookings,
//     required this.memberSince,
//     this.lastVisit,
//     required this.avatarInitials,
//   });
//
//   factory Customer.fromJson(Map<String, dynamic> json) {
//     return Customer(
//       id: json['id'],
//       name: json['name'],
//       email: json['email'],
//       phone: json['phone'],
//       points: json['points'],
//       status: json['status'],
//       totalSpent: json['totalSpent']?.toDouble() ?? 0.0,
//       totalBookings: json['totalBookings'],
//       memberSince: DateTime.parse(json['memberSince']),
//       lastVisit: json['lastVisit'] != null ? DateTime.parse(json['lastVisit']) : null,
//       avatarInitials: json['avatarInitials'],
//     );
//   }
// }
//
// class CustomerHistory {
//   final String customerId;
//   final List<BookingHistory> bookings;
//   final List<Feedback> feedbacks;
//   final List<LoyaltyTransaction> loyaltyTransactions;
//   final LoyaltySummary loyaltySummary;
//
//   CustomerHistory({
//     required this.customerId,
//     required this.bookings,
//     required this.feedbacks,
//     required this.loyaltyTransactions,
//     required this.loyaltySummary,
//   });
// }
//
// class BookingHistory {
//   final String bookingId;
//   final DateTime date;
//   final String service;
//   final String staff;
//   final String status;
//   final double amount;
//   final int pointsEarned;
//
//   BookingHistory({
//     required this.bookingId,
//     required this.date,
//     required this.service,
//     required this.staff,
//     required this.status,
//     required this.amount,
//     required this.pointsEarned,
//   });
// }
//
// class Feedback {
//   final DateTime date;
//   final String status; // responded, pending
//   final String comment;
//   final String? response;
//   final DateTime? respondedOn;
//
//   Feedback({
//     required this.date,
//     required this.status,
//     required this.comment,
//     this.response,
//     this.respondedOn,
//   });
// }
//
// class LoyaltyTransaction {
//   final DateTime date;
//   final String type; // earned, redeemed, bonus
//   final String description;
//   final int points;
//   final int balance;
//
//   LoyaltyTransaction({
//     required this.date,
//     required this.type,
//     required this.description,
//     required this.points,
//     required this.balance,
//   });
// }
//
// class LoyaltySummary {
//   final int currentBalance;
//   final int earnedThisMonth;
//   final int totalRedeemed;
//   final int totalEarned;
//
//   LoyaltySummary({
//     required this.currentBalance,
//     required this.earnedThisMonth,
//     required this.totalRedeemed,
//     required this.totalEarned,
//   });
// }