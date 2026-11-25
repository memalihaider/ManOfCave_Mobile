import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../controlers/auth_controller.dart';
import 'customer_shell.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? email;

  const EmailVerificationScreen({
    super.key,
    this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthController authController = Get.find<AuthController>();
  final GetStorage _storage = GetStorage();

  bool _isCreatingAccount = false;
  bool _isSendingEmail = false;
  String? _verificationMessage;
  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // The verification email is already sent by AuthController.createAuthAccount
    // just before navigating to this screen.
    // We don't call _sendVerificationEmail() here to avoid triggering
    // Firebase rate limits (too-many-requests).
  }

  Future<void> _sendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isSendingEmail = true;
      _verificationMessage = null;
    });

    final success = await authController.sendEmailVerification();

    if (success) {
      _startResendTimer();
    } else if (mounted) {
      setState(() {
        _verificationMessage = authController.errorMessage.value.isEmpty
            ? 'Failed to send verification email'
            : authController.errorMessage.value;
      });
    }

    setState(() {
      _isSendingEmail = false;
    });
  }

  void _startResendTimer() {
    setState(() {
      _resendCooldown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendCooldown--;
        });
      }
    });
  }

  Future<void> _createAccount() async {
    setState(() {
      _isCreatingAccount = true;
      _verificationMessage = null;
    });

    try {
      // Check if email is verified first
      final isVerified = await authController.checkEmailVerification();

      if (!isVerified) {
        setState(() {
          _verificationMessage = 'Please verify your email first. Check your inbox and click the verification link.';
          _isCreatingAccount = false;
        });
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _verificationMessage = 'Your session has expired. Please try signing up again.';
          _isCreatingAccount = false;
        });
        return;
      }

      // Get pending data from AuthController/Storage
      final pendingData = authController.pendingUserData;
      
      if (pendingData == null) {
         setState(() {
          _verificationMessage = 'Registration data lost. Please try signing up again.';
          _isCreatingAccount = false;
        });
        return;
      }

      // Complete registration after verification
      final success = await authController.completeRegistrationAfterVerification(
        uid: user.uid,
        name: pendingData['name'] ?? 'Customer',
        email: pendingData['email'] ?? user.email ?? '',
        phone: pendingData['phone'] ?? '',
        dateOfBirth: pendingData['dateOfBirth'],
      );

      if (success && mounted) {
        // Clear pending data on success
        authController.clearPendingUserData();
        
        Get.offAll(
              () => const CustomerShell(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );
      } else {
        setState(() {
          _verificationMessage = authController.errorMessage.value.isEmpty
              ? 'Failed to create your account. Please try again.'
              : authController.errorMessage.value;
          _isCreatingAccount = false;
        });
      }
    } catch (e) {
      setState(() {
        _verificationMessage = 'An error occurred: ${e.toString()}';
        _isCreatingAccount = false;
      });
    }
  }

  Future<void> _logout() async {
    await authController.logout();
  }

  String get _displayEmail {
    if (widget.email != null && widget.email!.isNotEmpty) return widget.email!;
    final pendingData = authController.pendingUserData;
    if (pendingData != null && pendingData['email'] != null) return pendingData['email'];
    return authController.pendingVerificationEmail ?? 'your email';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Registration?'),
            content: const Text(
                'Are you sure you want to cancel registration?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continue'),
              ),
              TextButton(
                onPressed: () {
                  _logout();
                  Navigator.pop(context, true);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          Get.offAll(() => const LoginScreen());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        body: SafeArea(
          child: Padding(
            padding: AppSizes.paddingAll(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: AppSizes.spaceExtraLarge32),

                  // Title
                  Text(
                    "Verify Your Email",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGold,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceMedium16),

                  // Main Container
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radius(16)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: AppSizes.paddingAll(20),
                    child: Column(
                      children: [
                        // Icon
                        Container(
                          padding: AppSizes.paddingAll(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mark_email_unread_outlined,
                            size: AppSizes.iconLarge60,
                            color: AppColors.primaryGold,
                          ),
                        ),
                        SizedBox(height: AppSizes.spaceMedium16),

                        // Email Display
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.spaceMedium16,
                            vertical: AppSizes.spaceSmall8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radius(8)),
                          ),
                          child: Text(
                            _displayEmail,
                            style: TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: AppSizes.font(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSizes.spaceMedium16),

                        // Instructions
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSizes.spaceMedium16),
                          child: Text(
                            "We've sent a verification email to your address. Please check your inbox and click the verification link.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSizes.spaceMedium16),

                        // Resend Button
                        Container(
                          padding: EdgeInsets.all(AppSizes.spaceMedium16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(AppSizes.radius(8)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Didn't receive the email?",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: AppSizes.font(14),
                                ),
                              ),
                              TextButton(
                                onPressed: (_isSendingEmail || _resendCooldown > 0) ? null : _sendVerificationEmail,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primaryGold,
                                ),
                                child: Text(
                                  _resendCooldown > 0 
                                      ? "Resend in ${_resendCooldown}s" 
                                      : "Resend Verification Email",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSizes.spaceSmall8),

                        // Spam folder hint
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: AppSizes.icon(16),
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: AppSizes.spaceSmall8),
                            Expanded(
                              child: Text(
                                "Check your spam folder if you don't see the email",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: AppSizes.font(12),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSizes.spaceLarge24),

                        // Error Message
                        if (_verificationMessage != null)
                          Container(
                            margin: AppSizes.paddingOnly(bottom: 16),
                            padding: AppSizes.paddingAll(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: AppSizes.iconSmall18),
                                SizedBox(width: AppSizes.spaceSmall8),
                                Expanded(
                                  child: Text(
                                    _verificationMessage!,
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: AppSizes.font(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Create Account Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isCreatingAccount ? null : _createAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.radius(8)),
                              ),
                              elevation: 0,
                              padding: AppSizes.paddingSymmetric(vertical: 16),
                            ),
                            child: _isCreatingAccount
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: AppSizes.width(20),
                                  height: AppSizes.height(20),
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: AppSizes.width(12)),
                                const Text("Processing..."),
                              ],
                            )
                                : Text(
                              "I've Verified My Email - Create Account",
                              style: TextStyle(
                                fontSize: AppSizes.font(14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppSizes.spaceMedium16),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}