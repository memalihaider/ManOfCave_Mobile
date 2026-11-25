// import 'package:get/get.dart';
// import '../models/customer_model.dart';
//
// class ReportsController extends GetxController {
//   // Reactive list of customers
//   var customers = <Customer>[].obs;
//   var filteredCustomers = <Customer>[].obs;
//   var searchQuery = ''.obs;
//   var isLoading = false.obs;
//   var selectedCustomer = Rxn<CustomerHistory>();
//
//   @override
//   void onInit() {
//     super.onInit();
//     loadCustomers();
//   }
//
//   void loadCustomers() {
//     isLoading.value = true;
//
//     // Simulate API delay
//     Future.delayed(const Duration(milliseconds: 500), () {
//       customers.assignAll([
//         Customer(
//           id: '1',
//           name: 'John Doe',
//           email: 'john.doe@email.com',
//           phone: '+1 (555) 123-4567',
//           points: 250,
//           status: 'active',
//           totalSpent: 450.00,
//           totalBookings: 8,
//           memberSince: DateTime(2024, 1, 15),
//           lastVisit: DateTime(2024, 12, 1),
//           avatarInitials: 'JD',
//         ),
//         Customer(
//           id: '2',
//           name: 'Jane Smith',
//           email: 'jane.smith@email.com',
//           points: 180,
//           status: 'active',
//           totalSpent: 320.00,
//           totalBookings: 6,
//           memberSince: DateTime(2024, 3, 20),
//           lastVisit: DateTime(2024, 11, 28),
//           avatarInitials: 'JS',
//         ),
//         Customer(
//           id: '3',
//           name: 'Bob Johnson',
//           email: 'bob.johnson@email.com',
//           points: 95,
//           status: 'inactive',
//           totalSpent: 180.00,
//           totalBookings: 4,
//           memberSince: DateTime(2024, 6, 10),
//           lastVisit: DateTime(2024, 10, 15),
//           avatarInitials: 'BJ',
//         ),
//         Customer(
//           id: '4',
//           name: 'Mike Wilson',
//           email: 'mike.wilson@email.com',
//           points: 320,
//           status: 'active',
//           totalSpent: 520.00,
//           totalBookings: 10,
//           memberSince: DateTime(2024, 2, 10),
//           lastVisit: DateTime(2024, 12, 5),
//           avatarInitials: 'MW',
//         ),
//         Customer(
//           id: '5',
//           name: 'Sarah Davis',
//           email: 'sarah.davis@email.com',
//           points: 75,
//           status: 'active',
//           totalSpent: 210.00,
//           totalBookings: 5,
//           memberSince: DateTime(2024, 7, 15),
//           lastVisit: DateTime(2024, 11, 20),
//           avatarInitials: 'SD',
//         ),
//       ]);
//
//       filteredCustomers.assignAll(customers);
//       isLoading.value = false;
//     });
//   }
//
//   void searchCustomers(String query) {
//     searchQuery.value = query;
//     if (query.isEmpty) {
//       filteredCustomers.assignAll(customers);
//     } else {
//       filteredCustomers.assignAll(
//         customers.where((customer) =>
//         customer.name.toLowerCase().contains(query.toLowerCase()) ||
//             customer.email.toLowerCase().contains(query.toLowerCase())).toList(),
//       );
//     }
//   }
//
//   void loadCustomerHistory(String customerId) {
//     if (customerId == '1') {
//       selectedCustomer.value = CustomerHistory(
//         customerId: customerId,
//         loyaltySummary: LoyaltySummary(
//           currentBalance: 250,
//           earnedThisMonth: 25,
//           totalRedeemed: 50,
//           totalEarned: 80,
//         ),
//         bookings: [
//           BookingHistory(
//             bookingId: 'B001',
//             date: DateTime(2024, 12, 1),
//             service: 'Premium Haircut',
//             staff: 'Mike Johnson',
//             status: 'completed',
//             amount: 45.00,
//             pointsEarned: 45,
//           ),
//           BookingHistory(
//             bookingId: 'B002',
//             date: DateTime(2024, 11, 15),
//             service: 'Beard Trim',
//             staff: 'Alex Chen',
//             status: 'completed',
//             amount: 25.00,
//             pointsEarned: 25,
//           ),
//           BookingHistory(
//             bookingId: 'B003',
//             date: DateTime(2024, 10, 20),
//             service: 'Haircut + Beard',
//             staff: 'Mike Johnson',
//             status: 'completed',
//             amount: 55.00,
//             pointsEarned: 55,
//           ),
//         ],
//         feedbacks: [
//           Feedback(
//             date: DateTime(2024, 12, 1),
//             status: 'responded',
//             comment: 'Excellent service! Mike did a great job with my haircut.',
//             response: "Thank you for your kind words, John! We're glad you enjoyed your experience.",
//             respondedOn: DateTime(2024, 12, 1),
//           ),
//           Feedback(
//             date: DateTime(2024, 10, 20),
//             status: 'pending',
//             comment: 'Service was okay, but I expected better styling.',
//           ),
//         ],
//         loyaltyTransactions: [
//           LoyaltyTransaction(
//             date: DateTime(2024, 12, 1),
//             type: 'earned',
//             description: 'Booking: Classic Haircut',
//             points: 25,
//             balance: 25,
//           ),
//           LoyaltyTransaction(
//             date: DateTime(2024, 11, 15),
//             type: 'redeemed',
//             description: 'Redeemed for 10% discount',
//             points: -50,
//             balance: -25,
//           ),
//           LoyaltyTransaction(
//             date: DateTime(2024, 11, 1),
//             type: 'bonus',
//             description: 'Birthday bonus points',
//             points: 10,
//             balance: -15,
//           ),
//           LoyaltyTransaction(
//             date: DateTime(2024, 10, 20),
//             type: 'earned',
//             description: 'Booking: Haircut + Beard',
//             points: 55,
//             balance: 40,
//           ),
//         ],
//       );
//     }
//   }
//
//   void clearSelectedCustomer() {
//     selectedCustomer.value = null;
//   }
//
//   void refreshData() {
//     loadCustomers();
//   }
//
//   // Statistics getters
//   int get totalCustomers => customers.length;
//   int get activeCustomers => customers.where((c) => c.status == 'active').length;
//   double get totalRevenue => customers.fold(0, (sum, customer) => sum + customer.totalSpent);
//   int get totalPoints => customers.fold(0, (sum, customer) => sum + customer.points);
// }