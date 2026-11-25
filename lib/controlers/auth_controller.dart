import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../Screens/login_screen.dart';
import '../Screens/otp_verification_screen.dart';
import '../models/CustomerModel.dart';
import '../models/user_model.dart';
import 'loyalty_points_controller.dart';
import 'referral_controller.dart'; // Add this import

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Storage keys
  static const String _storageKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _lastBirthdayCheckKey = 'last_birthday_check';
  static const String _pendingVerificationEmailKey = 'pending_verification_email';
  static const String _emailVerifiedKey = 'email_verified';
  static const String _pendingUserDataKey = 'pending_user_data';
  static const String _registrationBonusAwardedKey = 'registration_bonus_awarded';
  static const String _birthdayBonusAwardedKey = 'birthday_bonus_awarded_';

  // Reactive state
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var loginErrorMessage = ''.obs;
  var signupErrorMessage = ''.obs;
  var currentUser = Rxn<UserModel>();
  var isLoggedIn = false.obs;

  // Email verification state
  var isEmailVerified = false.obs;
  var isEmailVerificationSent = false.obs;

  LoyaltyController? _loyaltyController;
  // ReferralController? _referralController; // Add referral controller reference

  // Flags to prevent duplicate processing
  bool _isProcessingRegistrationBonus = false;
  final Set<String> _processedRegistrationUsers = {};
  final Set<String> _processedBirthdayUsers = {};

  @override
  void onInit() {
    super.onInit();
    _checkLocalStorage();
    _loyaltyController = Get.find<LoyaltyController>();
    // _referralController = Get.find<ReferralController>(); // Initialize referral controller

    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .get()
              .timeout(const Duration(seconds: 8));

          if (userDoc.exists) {
            await firebaseUser.reload();
            isEmailVerified.value = firebaseUser.emailVerified;
            await _getUserData(firebaseUser.uid);
            isLoggedIn.value = true;

            _storage.write(_emailVerifiedKey, firebaseUser.emailVerified);
            await saveFCMToken();
          } else {
            currentUser.value = null;
            isLoggedIn.value = false;
          }
        } catch (e) {
          print('⚠️ Auth user doc load skipped: $e');
          // Keep any locally cached session; don't hang splash/login.
        }
      } else {
        currentUser.value = null;
        isLoggedIn.value = false;
        isEmailVerified.value = false;
        _clearLocalStorage();
      }
    });
  }

  // Clear error messages
  void clearErrors() {
    errorMessage.value = '';
    loginErrorMessage.value = '';
    signupErrorMessage.value = '';
  }

  Future<void> saveFCMToken() async {
    try {
      final userId = currentUser.value?.uid;
      if (userId == null) return;

      String? token = await _fcm.getToken();
      if (token == null) return;

      print('📱 Saving FCM Token: $token');

      final existingTokens = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in existingTokens.docs) {
        batch.update(doc.reference, {'active': false});
      }

      final tokenRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token);

      batch.set(tokenRef, {
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'active': true,
        'device': {
          'platform': 'android',
          'model': null,
        }
      });

      await batch.commit();
      print('✅ FCM Token saved as ACTIVE for user: $userId');

      await _fcm.subscribeToTopic('all_users');
      await _fcm.subscribeToTopic('offers');

    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  Future<void> removeFCMToken() async {
    try {
      final userId = currentUser.value?.uid;
      if (userId == null) return;

      String? token = await _fcm.getToken();
      if (token != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('fcmTokens')
            .doc(token)
            .update({
          'active': false,
          'removedAt': FieldValue.serverTimestamp(),
        });
      }

      await _fcm.unsubscribeFromTopic('all_users');
      await _fcm.unsubscribeFromTopic('admins');
      await _fcm.unsubscribeFromTopic('customers');
      await _fcm.unsubscribeFromTopic('offers');

      print('✅ FCM Token removed');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }

  String? getUserBranchId() {
    return currentUser.value?.branchId;
  }

  String? getUserBranchName() {
    return currentUser.value?.branchName;
  }

  void _checkLocalStorage() {
    try {
      final isLoggedInLocally = _storage.read(_isLoggedInKey) ?? false;
      final userId = _storage.read(_userIdKey);
      final userData = _storage.read(_storageKey);
      final emailVerifiedLocally = _storage.read(_emailVerifiedKey) ?? false;

      if (isLoggedInLocally && userId != null && userData != null) {
        final user = UserModel.fromLocalStorage(userData, userId);
        currentUser.value = user;
        isLoggedIn.value = true;
        isEmailVerified.value = emailVerifiedLocally;
        print('User restored from local storage: ${user.name} (${user.role})');
      }
    } catch (e) {
      print('Error reading from local storage: $e');
      _clearLocalStorage();
    }
  }

  void _saveUserToLocalStorage(UserModel user) {
    try {
      _storage.write(_isLoggedInKey, true);
      _storage.write(_userIdKey, user.uid);
      _storage.write(_storageKey, user.toLocalStorage());
      _storage.write(_emailVerifiedKey, isEmailVerified.value);
      print('User saved to local storage: ${user.name}');
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }

  void _clearLocalStorage() {
    try {
      _storage.remove(_isLoggedInKey);
      _storage.remove(_userIdKey);
      _storage.remove(_storageKey);
      _storage.remove(_lastBirthdayCheckKey);
      _storage.remove(_pendingVerificationEmailKey);
      _storage.remove(_emailVerifiedKey);
      _storage.remove(_pendingUserDataKey);
      print('Local storage cleared');
    } catch (e) {
      print('Error clearing local storage: $e');
    }
  }

  bool isValidDateOfBirth(String? dateOfBirth) {
    if (dateOfBirth == null || dateOfBirth.isEmpty) return true;
    try {
      final date = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      final hundredYearsAgo = DateTime(now.year - 100, now.month, now.day);
      return date.isBefore(now) && date.isAfter(hundredYearsAgo);
    } catch (e) {
      return false;
    }
  }

  String formatDateOfBirth(String? dateOfBirth) {
    if (dateOfBirth == null || dateOfBirth.isEmpty) return '';
    try {
      final date = DateTime.parse(dateOfBirth);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateOfBirth;
    }
  }

  bool _isTodayBirthday(String? dateOfBirth) {
    if (dateOfBirth == null || dateOfBirth.isEmpty) return false;
    try {
      final birthDate = DateTime.parse(dateOfBirth);
      final today = DateTime.now();
      return today.month == birthDate.month && today.day == birthDate.day;
    } catch (e) {
      return false;
    }
  }

  bool _shouldCheckBirthdayToday() {
    final lastCheckDate = _storage.read<String>(_lastBirthdayCheckKey);
    if (lastCheckDate == null) return true;

    try {
      final lastCheck = DateTime.parse(lastCheckDate);
      final today = DateTime.now();
      return lastCheck.year != today.year ||
          lastCheck.month != today.month ||
          lastCheck.day != today.day;
    } catch (e) {
      return true;
    }
  }

  void _updateLastBirthdayCheck() {
    final today = DateTime.now().toIso8601String();
    _storage.write(_lastBirthdayCheckKey, today);
  }

  Future<void> _checkBirthdayBonus(String userId) async {
    // Loyalty birthday bonuses removed — portal uses e-wallet only.
  }

  Future<void> checkBirthdayBonusFromSplash() async {
    // no-op
  }

  // ==================== EMAIL VERIFICATION METHODS ====================

  Future<bool> sendEmailVerification() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;

      await user?.reload();
      if (user!.emailVerified) {
        isEmailVerified.value = true;
        _storage.write(_emailVerifiedKey, true);
        errorMessage.value = 'Email already verified';
        return false;
      }

      await user.sendEmailVerification();
      isEmailVerificationSent.value = true;
      _storage.write(_pendingVerificationEmailKey, user.email);

      Get.snackbar(
        'Verification Email Sent',
        'Please check your email (${user.email}) and click the verification link',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getAuthErrorMessage(e.code);
      return false;
    } catch (e) {
      errorMessage.value = 'Failed to send verification email';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      isLoading.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        errorMessage.value = 'No user logged in';
        return false;
      }

      await user.reload();
      final updatedUser = _auth.currentUser!;

      final verified = updatedUser.emailVerified;
      isEmailVerified.value = verified;

      if (verified) {
        _storage.remove(_pendingVerificationEmailKey);
        _storage.write(_emailVerifiedKey, true);
      }

      return verified;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    try {
      isLoading.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        errorMessage.value = 'No user logged in';
        return false;
      }

      if (user.emailVerified) {
        isEmailVerified.value = true;
        errorMessage.value = 'Email already verified';
        return false;
      }

      await user.sendEmailVerification();

      Get.snackbar(
        'Verification Email Resent',
        'Please check your email (${user.email})',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to resend verification email';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== REGISTRATION FLOW ====================

  Future<bool> createAuthAccount({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? dateOfBirth,
  }) async {
    try {
      isLoading.value = true;
      signupErrorMessage.value = '';

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final pendingData = {
        'uid': userCredential.user!.uid,
        'email': email.trim(),
        'name': name.trim(),
        'phone': phone.trim(),
        'dateOfBirth': dateOfBirth,
        'createdAt': DateTime.now().toIso8601String(),
      };
      _storage.write(_pendingUserDataKey, pendingData);
      _storage.write(_pendingVerificationEmailKey, email.trim());

      await userCredential.user!.sendEmailVerification();
      isEmailVerificationSent.value = true;

      return true;
    } on FirebaseAuthException catch (e) {
      signupErrorMessage.value = _getSignupErrorMessage(e.code);
      return false;
    } catch (e) {
      signupErrorMessage.value = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic>? get pendingUserData {
    return _storage.read(_pendingUserDataKey);
  }

  void clearPendingUserData() {
    _storage.remove(_pendingUserDataKey);
    _storage.remove(_pendingVerificationEmailKey);
  }

  Future<bool> completeRegistrationAfterVerification({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? dateOfBirth,
    String role = 'customer',
    String? branchId,
    String? branchName,
    String? referralCode, // Add referral code parameter
  }) async {
    // Prevent duplicate processing
    if (_isProcessingRegistrationBonus) {
      print("⚠️ Registration bonus already being processed, skipping");
      return false;
    }

    if (_processedRegistrationUsers.contains(uid)) {
      print("⚠️ Registration already processed for user: $uid");
      return false;
    }

    try {
      _isProcessingRegistrationBonus = true;
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null || user.uid != uid) {
        errorMessage.value = 'User not found';
        return false;
      }

      await user.reload();
      if (!user.emailVerified) {
        errorMessage.value = 'Email not verified yet';
        return false;
      }

      final formattedDateOfBirth = dateOfBirth != null && dateOfBirth.isNotEmpty
          ? formatDateOfBirth(dateOfBirth)
          : null;

      final now = DateTime.now();

      // Generate referral code for the new user using ReferralController
      // String? newReferralCode;
      // if (_referralController != null) {
      //   newReferralCode = _referralController!.generateReferralCode(name, uid);
      //   print('🔑 Generated referral code: $newReferralCode for user: $name');
      // } else {
      //   print('⚠️ Error generating referral code');
      // }

      final newUser = UserModel(
        uid: uid,
        email: email.trim(),
        name: name.trim(),
        role: role,
        status: 'active',
        createdAt: now,
        updatedAt: now,
        phone: phone.trim(),
        dateOfBirth: formattedDateOfBirth,
        branchId: branchId,
        branchName: branchName,
        emailVerified: true,
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .set(newUser.toFirestore());

      // Prepare customer data with referral fields
      final customerData = {
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role,
        'status': 'active',
        'emailVerified': true,
        'dateOfBirth': formattedDateOfBirth,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'lastLogin': Timestamp.fromDate(now),
        'referralCount': 0,
        'referralEarnings': 0.0,
        'referralDiscountUsed': 0.0,
        if (branchId != null) 'branchId': branchId,
        if (branchName != null) 'branchName': branchName,
      };
      //
      // // Apply referral code if provided (user was referred by someone)
      // if (referralCode != null && referralCode.isNotEmpty && _referralController != null) {
      //   print('🔍 Applying referral code during signup: $referralCode');
      //   final isValid = await _referralController!.validateReferralCodeForCheckout(
      //       referralCode,
      //       uid
      //   );
      //
      //   if (isValid) {
      //     await _referralController!.applyReferralCodeOnSignup(uid, referralCode);
      //     print('✅ Referral code applied: $referralCode');
      //
      //     // Add referral info to customer data
      //     customerData['referredByCode'] = referralCode.toUpperCase();
      //
      //     // Show success message
      //     Get.snackbar(
      //       'Referral Code Applied! 🎉',
      //       'You will get discount on your first booking/order!',
      //       snackPosition: SnackPosition.BOTTOM,
      //       backgroundColor: Colors.green,
      //       colorText: Colors.white,
      //       duration: const Duration(seconds: 3),
      //     );
      //   } else {
      //     print('⚠️ Invalid referral code provided: $referralCode');
      //     Get.snackbar(
      //       'Invalid Referral Code',
      //       'The referral code you entered is invalid',
      //       snackPosition: SnackPosition.BOTTOM,
      //       backgroundColor: Colors.orange,
      //       colorText: Colors.white,
      //       duration: const Duration(seconds: 3),
      //     );
      //   }
      // }

      await _firestore
          .collection('customers')
          .doc(uid)
          .set(customerData);

      currentUser.value = newUser;
      isLoggedIn.value = true;
      isEmailVerified.value = true;

      _saveUserToLocalStorage(newUser);

      _storage.remove(_pendingUserDataKey);
      _storage.remove(_pendingVerificationEmailKey);

      await saveFCMToken();

      // Loyalty bonuses removed — portal uses e-wallet only (staff-managed).
      return true;
    } catch (e) {
      errorMessage.value = 'Error completing registration: ${e.toString()}';
      _processedRegistrationUsers.remove(uid);
      return false;
    } finally {
      isLoading.value = false;
      _isProcessingRegistrationBonus = false;
    }
  }

  Future<void> _awardBonuses(
      String userId,
      String name,
      String? dateOfBirth,
      String? branchId,
      String? branchName,
      ) async {
    try {
      int totalPoints = 0;

      if (_loyaltyController != null) {
        // Award registration bonus (only once per user)
        print("🎁 Awarding registration bonus for user: $userId");
        await _loyaltyController!.awardRegistrationBonus(userId);
        totalPoints += 100;
        print("✅ Registration bonus awarded: 100 points");

        // Check for birthday bonus
        if (dateOfBirth != null && _isTodayBirthday(dateOfBirth)) {
          final birthdayKey = "${userId}_${DateTime.now().year}";
          if (!_processedBirthdayUsers.contains(birthdayKey)) {
            print("🎂 Awarding birthday bonus for user: $name");
            await _loyaltyController!.awardBirthdayBonus(
              customerId: userId,
              customerName: name,
              branchId: branchId,
              branchName: branchName,
            );
            totalPoints += 200;
            _processedBirthdayUsers.add(birthdayKey);
            print("✅ Birthday bonus awarded: 200 points");
          } else {
            print("⚠️ Birthday bonus already awarded today, skipping");
          }
        }

        if (totalPoints > 0) {
          Get.snackbar(
            'Bonus Points Awarded! 🎉',
            'You received $totalPoints bonus points',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      print('❌ Error awarding bonuses: $e');
    }
  }

  // ==================== EXISTING METHODS ====================

  Future<void> _getUserData(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final user = UserModel.fromFirestore(userDoc.data()!, userDoc.id);
        currentUser.value = user;
        _saveUserToLocalStorage(user);
        await _updateCustomerLastLogin(userId);
      }
    } catch (e) {
      errorMessage.value = 'Error fetching user data: $e';
    }
  }

  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      loginErrorMessage.value = '';

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final userId = userCredential.user!.uid;

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        loginErrorMessage.value = 'Account not fully set up. Please complete registration.';
        await _auth.signOut();
        return false;
      }

      await userCredential.user!.reload();
      final isVerified = userCredential.user!.emailVerified;
      isEmailVerified.value = isVerified;

      if (!isVerified) {
        Get.snackbar(
          'Email Not Verified',
          'Please verify your email to access all features. You can also verify from your profile.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }

      await _getUserData(userId);

      return true;
    } on FirebaseAuthException catch (e) {
      loginErrorMessage.value = _getLoginErrorMessage(e.code);
      return false;
    } catch (e) {
      loginErrorMessage.value = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? dateOfBirth,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = currentUser.value;
      if (user == null) {
        errorMessage.value = 'No user logged in';
        return false;
      }

      if (dateOfBirth != null && dateOfBirth.isNotEmpty && !isValidDateOfBirth(dateOfBirth)) {
        errorMessage.value = 'Invalid date of birth format. Use YYYY-MM-DD';
        return false;
      }

      final formattedDateOfBirth = dateOfBirth != null && dateOfBirth.isNotEmpty
          ? formatDateOfBirth(dateOfBirth)
          : null;

      final isDateOfBirthAdded = user.dateOfBirth == null && formattedDateOfBirth != null;
      final userId = user.uid;
      final now = DateTime.now();

      final updateData = {
        'updatedAt': Timestamp.fromDate(now),
        if (name != null && name.isNotEmpty) 'name': name,
        if (phone != null) 'phone': phone,
        if (dateOfBirth != null) 'dateOfBirth': formattedDateOfBirth,
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .update(updateData);

      try {
        await _firestore
            .collection('customers')
            .doc(userId)
            .update(updateData);
      } catch (e) {
        print('Note: Customer document might not exist yet: $e');
      }

      await _getUserData(userId);

      if (isDateOfBirthAdded && formattedDateOfBirth != null && isEmailVerified.value) {
        if (_isTodayBirthday(formattedDateOfBirth)) {
          await _loyaltyController?.awardBirthdayBonus(
            customerId: userId,
            customerName: name ?? user.name,
            branchId: user.branchId,
            branchName: user.branchName,
          );

          Get.snackbar(
            'Happy Birthday! 🎉',
            'Profile updated successfully! You received 200 birthday bonus points.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.pink,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Success',
            'Profile updated successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

      return true;
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
      Get.snackbar(
        'Error',
        'Failed to update profile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        errorMessage.value = 'No user logged in';
        return false;
      }

      final email = user.email;
      if (email == null) {
        errorMessage.value = 'Email not found';
        return false;
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      Get.snackbar(
        'Success',
        'Password changed successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getAuthErrorMessage(e.code);
      return false;
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateCustomerLastLogin(String userId) async {
    try {
      final now = DateTime.now();
      await _firestore
          .collection('customers')
          .doc(userId)
          .update({
        'lastLogin': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      print('Error updating customer last login: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _auth.sendPasswordResetEmail(email: email.trim());

      Get.snackbar(
        'Success',
        'Password reset email sent to $email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getAuthErrorMessage(e.code);
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      errorMessage.value = 'An error occurred. Please try again.';
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await removeFCMToken();

      await _auth.signOut();
      currentUser.value = null;
      isLoggedIn.value = false;
      isEmailVerified.value = false;
      isEmailVerificationSent.value = false;
      _clearLocalStorage();
      clearErrors();

      Get.snackbar(
        'Success',
        'Logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAll(() => LoginScreen());
    } catch (e) {
      errorMessage.value = 'Error logging out: $e';
    }
  }

  // ==================== HELPER METHODS ====================

  int? get userAge {
    final dateOfBirth = currentUser.value?.dateOfBirth;
    if (dateOfBirth == null || dateOfBirth.isEmpty) return null;
    try {
      final birthDate = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  bool get hasDateOfBirth {
    final dateOfBirth = currentUser.value?.dateOfBirth;
    return dateOfBirth != null && dateOfBirth.isNotEmpty;
  }

  String get formattedDateOfBirth {
    final dateOfBirth = currentUser.value?.dateOfBirth;
    if (dateOfBirth == null || dateOfBirth.isEmpty) return 'Not set';
    try {
      final date = DateTime.parse(dateOfBirth);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateOfBirth;
    }
  }

  bool get isTodayBirthday {
    final dateOfBirth = currentUser.value?.dateOfBirth;
    return _isTodayBirthday(dateOfBirth);
  }

  Future<void> refreshUserRole() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _getUserData(userId);
      }
    } catch (e) {
      print('Error refreshing user role: $e');
    }
  }

  bool hasRole(String role) {
    return currentUser.value?.role.toLowerCase() == role.toLowerCase();
  }

  String get formattedRole {
    final role = currentUser.value?.role ?? 'customer';
    switch (role.toLowerCase()) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
      case 'branch_admin':
        return 'Branch Admin';
      case 'customer':
        return 'Customer';
      case 'staff':
        return 'Staff';
      default:
        return role;
    }
  }

  bool get isSuperAdmin => hasRole('super_admin');
  bool get isBranchAdmin => hasRole('admin') || hasRole('branch_admin');
  bool get isCustomer => hasRole('customer');
  bool get isStaff => hasRole('staff');
  bool get isAdmin => isSuperAdmin || isBranchAdmin;

  String _getLoginErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Login failed. Please check your credentials and try again.';
    }
  }

  String _getSignupErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters with mix of letters and numbers.';
      case 'operation-not-allowed':
        return 'Email/Password sign up is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many registration attempts. Please try again later.';
      default:
        return 'Sign up failed ($errorCode). Please try again.';
    }
  }

  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters).';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred ($errorCode). Please try again.';
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  Future<int> getUserLoyaltyPoints() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final walletDoc = await _firestore
          .collection('wallets')
          .doc(userId)
          .get();

      if (walletDoc.exists) {
        final data = walletDoc.data() as Map<String, dynamic>;
        return (data['balance'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting loyalty points: $e');
      return 0;
    }
  }

  String? get pendingVerificationEmail {
    return _storage.read(_pendingVerificationEmailKey);
  }

  void clearPendingVerification() {
    _storage.remove(_pendingVerificationEmailKey);
  }
}
