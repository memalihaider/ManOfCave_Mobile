import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:man_of_cave/constants/app_strings.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../controlers/auth_controller.dart';
import '../controlers/product_controller.dart';
import '../controlers/service_controller.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/elevated_button.dart';
import '../widgets/outlined_button.dart';
import '../widgets/text_button.dart';
import 'AdminScreens/dashboard_screen.dart';
import 'customer_shell.dart';
import 'signUp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthController authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateBasedOnRole() {
    final user = authController.currentUser.value;
    if (user == null) return;

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

    if (authController.isAdmin ||
        authController.isSuperAdmin ||
        authController.isBranchAdmin) {
      Get.offAll(
        () => DashboardScreen(),
        duration: const Duration(milliseconds: 300),
      );
    } else {
      Get.offAll(
        () => const CustomerShell(),
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldSoft,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 28.h),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 52.w,
                            height: 52.w,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold,
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Icon(
                              Icons.content_cut_rounded,
                              color: AppColors.white,
                              size: 26.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 28.h),
                        Text(
                          AppStrings.appName,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textInk,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Sign in to book and manage your visits',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: 28.h),
                        Obx(() {
                          if (authController.loginErrorMessage.value.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            margin: EdgeInsets.only(bottom: 16.h),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade700, size: 20.sp),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    authController.loginErrorMessage.value,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textInk,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              CustomTextfield(
                                hintText: 'you@email.com',
                                controller: _emailController,
                                prefixIcon: const Icon(Icons.mail_outline_rounded),
                                textInputType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!authController.isValidEmail(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Password',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textInk,
                                    ),
                                  ),
                                  CustomTextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    text: 'Forgot?',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              CustomTextfield(
                                hintText: 'Your password',
                                controller: _passwordController,
                                isPass: _obscurePassword,
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (!authController.isValidPassword(value)) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(height: 24.h),
                              Obx(() {
                                return SizedBox(
                                  width: double.infinity,
                                  child: CustomElevatedButton(
                                    onPressed: _handleLogin,
                                    text: 'Sign in',
                                    isLoading: authController.isLoading.value,
                                  ),
                                );
                              }),
                              SizedBox(height: 12.h),
                              SizedBox(
                                width: double.infinity,
                                child: CustomOutlinedButton(
                                  onPressed: () {
                                    Get.offAll(
                                      () => const CustomerShell(),
                                      duration: const Duration(milliseconds: 300),
                                    );
                                  },
                                  text: 'Continue as guest',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(height: 24.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14.sp,
                              ),
                            ),
                            CustomTextButton(
                              onPressed: () {
                                Get.offAll(
                                  () => const SignupScreen(),
                                  transition: Transition.rightToLeft,
                                  duration: const Duration(milliseconds: 300),
                                );
                              },
                              text: 'Sign up',
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'By continuing you agree to our Terms & Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.sp,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    authController.errorMessage.value = '';
    final success = await authController.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success) {
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateBasedOnRole();
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
        ),
        title: Text(
          'Reset Password',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.textInk,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email and we\'ll send a reset link.',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email address',
                prefixIcon: const Icon(Icons.mail_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !authController.isValidEmail(email)) {
                Get.snackbar(
                  'Invalid email',
                  'Please enter a valid email address',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              Get.back();
              await authController.resetPassword(email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
  }
}
