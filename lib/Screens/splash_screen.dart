import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:man_of_cave/constants/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../controlers/auth_controller.dart';
import '../controlers/product_controller.dart';
import '../controlers/service_controller.dart';
import 'AdminScreens/dashboard_screen.dart';
import 'customer_shell.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';
import 'intro_screen.dart'; // Add this import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _initializationComplete = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeApp();
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Hard ceiling so a hung Firestore/FCM call can't leave a blank/black splash.
      await Future.any([
        _bootAndRoute(),
        Future.delayed(const Duration(seconds: 3), () {
          if (!_initializationComplete && mounted) {
            print('⚠️ Splash timeout — opening login');
            _goToLogin();
          }
        }),
      ]);
    } catch (e) {
      print('Error in splash screen: $e');
      _goToLogin();
    }
  }

  Future<void> _bootAndRoute() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    await _checkAuthentication();
  }

  void _goToLogin() {
    if (_initializationComplete) return;
    _initializationComplete = true;
    if (mounted) setState(() {});
    Get.offAll(() => const LoginScreen());
  }

  Future<void> _checkAuthentication() async {
    try {
      final authController = Get.find<AuthController>();

      // Give auth a short moment; don't block on remote Firestore.
      await Future.delayed(const Duration(milliseconds: 400));

      if (authController.isLoggedIn.value &&
          authController.currentUser.value != null) {
        await _handleLoggedInUser(authController);
      } else {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null &&
            !firebaseUser.emailVerified &&
            authController.pendingUserData != null) {
          _initializationComplete = true;
          if (mounted) setState(() {});
          Get.offAll(() => const EmailVerificationScreen());
        } else {
          _goToLogin();
        }
      }
    } catch (e) {
      print('Auth check error: $e');
      _goToLogin();
    }
  }

  // void _navigateToIntroScreen() {
  //   Get.offAll(() => IntroScreen(
  //     onIntroComplete: () {
  //       // Mark intro as seen
  //       _markIntroAsSeen();
  //       // Navigate to login after intro
  //       Get.offAll(() => const LoginScreen());
  //     },
  //   ));
  // }

  Future<void> _markIntroAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenIntro', true);
  }

  Future<void> _handleLoggedInUser(AuthController authController) async {
    try {
      final user = authController.currentUser.value!;

      // Initialize controllers with user role
      final productController = Get.find<ProductController>();
      final serviceController = Get.find<ServiceController>();

      productController.setUserRole(
        user.role,
        branchId: user.branchId,
        branchName: user.branchName,
      );

      serviceController.setUserRole(
        user.role,
        branchId: user.branchId,
        branchName: user.branchName,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      _initializationComplete = true;

      // Navigate based on role
      if (authController.isAdmin || authController.isSuperAdmin || authController.isBranchAdmin) {
        Get.offAll(() => DashboardScreen());
      } else {
        Get.offAll(() => const CustomerShell());
      }

      // Show welcome back message after a delay
      Future.delayed(const Duration(milliseconds: 800), () {
        Get.snackbar(
          'Welcome Back!',
          'Hello, ${user.name}!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryGold,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      });
    } catch (e) {
      print('Error handling logged in user: $e');
      Get.offAll(() => const LoginScreen());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(360, 800));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFDF6E9),
              Color(0xFFFAF0DC),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon with Animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 140.w,
                    height: 140.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGold.withOpacity(0.3),
                          blurRadius: 20.r,
                          spreadRadius: 2.r,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30.r),
                      child: _buildAppIcon(),
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                // App Name with Fade & Slide Animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Text(
                          AppStrings.appName,
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 8.h),

                        // App Tagline
                        Text(
                          'Premium Beauty & Wellness',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 60.h),

                // Loading Indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGold.withOpacity(0.2),
                              blurRadius: 10.r,
                              spreadRadius: 1.r,
                            ),
                          ],
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.w,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryGold,
                              ),
                              backgroundColor: AppColors.primaryGold.withOpacity(0.1),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Loading Text
                      Text(
                        _initializationComplete ? 'Redirecting...' : 'Preparing your experience...',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build App Icon Widget
  Widget _buildAppIcon() {
    try {
      return Image.asset(
        'assets/Images/man_of_cave_logo.jpeg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon();
        },
      );
    } catch (e) {
      return _buildFallbackIcon();
    }
  }

  // Fallback icon if asset doesn't exist
  Widget _buildFallbackIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGold.withOpacity(0.8),
            AppColors.primaryGold.withOpacity(0.4),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.spa_rounded,
          size: 60.w,
          color: Colors.white,
        ),
      ),
    );
  }
}