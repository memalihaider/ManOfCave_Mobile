import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../controlers/customer_controller.dart';
import 'chats/chat_list_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'my_booking_screen.dart';
import 'profile_screen.dart';

/// Native customer shell — bottom tabs instead of website-style chrome.
class CustomerShell extends StatefulWidget {
  final int initialIndex;

  const CustomerShell({super.key, this.initialIndex = 0});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late int _index;
  final _customer = Get.find<CustomerController>();

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  bool get _authed => _customer.isAuthenticated;

  void _onTap(int i) {
    if (i != 0 && !_authed) {
      Get.to(() => const LoginScreen());
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldSoft,
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(embedded: true),
          const MyBookingsScreen(),
          const ChatListScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            child: BottomNavigationBar(
              currentIndex: _index,
              onTap: _onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primaryGold,
              unselectedItemColor: AppColors.textMuted,
              selectedFontSize: 11.sp,
              unselectedFontSize: 11.sp,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  activeIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Bookings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  activeIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
