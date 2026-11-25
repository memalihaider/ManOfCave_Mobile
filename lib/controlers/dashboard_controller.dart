import 'package:get/get.dart';

class DashboardController extends GetxController {
  var selectedIndex = 0.obs;
  var todayAppointments = 24.obs;
  var monthlyRevenue = 12500.obs;
  var pendingApprovals = 8.obs;
  var activeBookings = 15.obs;

  // Analytics data
  var monthlyData = [12000.0, 19000.0, 15000.0, 22000.0, 18000.0, 25000.0, 30000.0].obs;
  var categories = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].obs;

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }
}