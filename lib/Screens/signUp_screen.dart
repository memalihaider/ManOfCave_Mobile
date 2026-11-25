import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../controlers/auth_controller.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/elevated_button.dart';
import '../widgets/text_button.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthController authController = Get.find<AuthController>();

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _selectedDate;

  // Add these for email verification info
  bool _acceptTerms = false;
  bool _showEmailVerificationInfo = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primaryGold,
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGold,
              onPrimary: Colors.white,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String? _validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) return null; // Optional field
    if (!authController.isValidDateOfBirth(value)) {
      return 'Invalid date format. Use YYYY-MM-DD';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        body: SafeArea(
          child: Padding(
            padding: AppSizes.paddingAll(16),
            child: SingleChildScrollView(
              child: Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Create Account",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceMedium16),

                    // Email Verification Info Banner - NEW
                    Container(
                      margin: AppSizes.paddingOnly(bottom: 16),
                      padding: AppSizes.paddingAll(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: AppSizes.paddingAll(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.email_outlined,
                              color: Colors.white,
                              size: AppSizes.iconSmall14,
                            ),
                          ),
                          SizedBox(width: AppSizes.width(4)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Email Verification Required",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                    fontSize: AppSizes.font(14),
                                  ),
                                ),
                                SizedBox(height: AppSizes.height(4)),
                                Text(
                                  "After signup, we'll send a verification link to your email. You'll need to verify your email.",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: AppSizes.font(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Error message if any
                    if (authController.signupErrorMessage.value.isNotEmpty)
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
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            SizedBox(width: AppSizes.width(8)),
                            Expanded(
                              child: Text(
                                authController.signupErrorMessage.value,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: AppSizes.font(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Signup Form Container
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: AppSizes.paddingAll(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Username Field
                            Text(
                              "Full Name",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey,
                              ),
                            ),
                            SizedBox(height: AppSizes.spaceSmall8),
                            CustomTextfield(
                              hintText: "Enter your full name",
                              controller: _usernameController,
                              prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                if (value.length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: AppSizes.spaceMedium16),

                            // Email Field
                            Text(
                              "Email Address",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey,
                              ),
                            ),
                            SizedBox(height: AppSizes.spaceSmall8),
                            CustomTextfield(
                              hintText: "Enter your email",
                              controller: _emailController,
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!authController.isValidEmail(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                              textInputType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: AppSizes.spaceMedium16),

                            // Password Field
                            Text(
                              "Password",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey,
                              ),
                            ),
                            SizedBox(height: AppSizes.spaceSmall8),
                            CustomTextfield(
                              hintText: "Enter your password...",
                              controller: _passwordController,
                              isPass: _obscurePassword,
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (!authController.isValidPassword(value)) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: AppSizes.spaceMedium16),

                            // Confirm Password Field
                            Text(
                              "Confirm Password",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey,
                              ),
                            ),
                            SizedBox(height: AppSizes.spaceSmall8),
                            CustomTextfield(
                              hintText: "Confirm your password...",
                              controller: _confirmPasswordController,
                              isPass: _obscureConfirmPassword,
                              prefixIcon: Icon(Icons.lock_outline, color: AppColors.grey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: AppSizes.spaceMedium16),

                            // Phone Number Field
                            Text(
                              "Phone Number",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey,
                              ),
                            ),
                            SizedBox(height: AppSizes.spaceSmall8),
                            CustomTextfield(
                              hintText: "+1 234 567 8900",
                              controller: _phoneController,
                              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.grey),
                              textInputType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                // Basic phone validation
                                if (value.length < 10) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: AppSizes.spaceSmall8),
                            Text(
                              "We'll send an OTP to verify your number later",
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: AppSizes.font(12),
                              ),
                            ),
                            SizedBox(height: AppSizes.spaceMedium16),

                            // Date of Birth Field
                            Text(
                              "Date of Birth (Optional)",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey,
                              ),
                            ),
                            SizedBox(height: AppSizes.spaceSmall8),
                            GestureDetector(
                              onTap: () => _selectDate(context),
                              child: AbsorbPointer(
                                child: CustomTextfield(
                                  hintText: "YYYY-MM-DD (Tap to select)",
                                  controller: _dobController,
                                  prefixIcon:  Icon(Icons.calendar_today, color: AppColors.grey),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      Icons.calendar_month,
                                      color: AppColors.primaryGold,
                                    ),
                                    onPressed: () => _selectDate(context),
                                  ),
                                  validator: _validateDateOfBirth,
                                  textInputType: TextInputType.datetime,
                                  readOnly: true,
                                  onTap: () => _selectDate(context),
                                ),
                              ),
                            ),
                            SizedBox(height: AppSizes.spaceSmall8),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: AppSizes.iconSmall14,
                                  color: Colors.grey[500],
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "Format: YYYY-MM-DD (e.g., 1990-05-15)",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: AppSizes.font(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSizes.spaceMedium16),

                            // Terms and Conditions Checkbox - NEW
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptTerms = value ?? false;
                                    });
                                  },
                                  activeColor: AppColors.primaryGold,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _acceptTerms = !_acceptTerms;
                                      });
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: AppSizes.font(13),
                                        ),
                                        children: [
                                          TextSpan(
                                            text: "I agree to the ",
                                          ),
                                          TextSpan(
                                            text: "Terms of Service",
                                            style: TextStyle(
                                              color: AppColors.primaryGold,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                          TextSpan(
                                            text: " and ",
                                          ),
                                          TextSpan(
                                            text: "Privacy Policy",
                                            style: TextStyle(
                                              color: AppColors.primaryGold,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSizes.spaceMedium16),

                            // Create Account Button
                            SizedBox(
                              width: double.infinity,
                              child: CustomElevatedButton(onPressed: _handleSignup, text: "Sign Up")

                            ),
                            SizedBox(height: AppSizes.spaceMedium16),

                            // Sign In Option
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                CustomTextButton(onPressed: (){
                                  Get.offAll(
                                        () => const LoginScreen(),
                                    transition: Transition.rightToLeft,
                                    duration: const Duration(milliseconds: 300),
                                  );
                                }, text: "Sign In")
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: AppSizes.spaceMedium16),

                    // Email Verification Steps - NEW
                    if (_showEmailVerificationInfo)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.mark_email_read,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Email Verification Steps:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildVerificationStep(1, "Check your inbox for verification email"),
                            _buildVerificationStep(2, "Click the verification link in the email"),
                            _buildVerificationStep(3, "Return to app and proceed to login"),
                            const SizedBox(height: 8),
                            Divider(color: Colors.blue.shade200),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Verification link expires in 24 hours",
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: AppSizes.spaceSmall8),

                    // Toggle verification info - NEW
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showEmailVerificationInfo = !_showEmailVerificationInfo;
                        });
                      },
                      child: Text(
                        _showEmailVerificationInfo ? "Hide verification info" : "How email verification works?",
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for verification steps
  Widget _buildVerificationStep(int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSignup() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Check terms acceptance
    if (!_acceptTerms) {
      Get.snackbar(
        'Terms & Conditions',
        'Please accept the Terms of Service and Privacy Policy to continue',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Validate form
    if (_formKey.currentState!.validate()) {
      // Clear any previous error
      authController.errorMessage.value = '';

      // Step 1: Create Auth account and store pending data
      final success = await authController.createAuthAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _usernameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _dobController.text.trim().isNotEmpty
            ? _dobController.text.trim()
            : null,
      );

      if (success) {
        // Navigate to verification screen
        Get.offAll(
              () => EmailVerificationScreen(
            email: _emailController.text.trim(),
          ),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );
      }
    }
  }
}