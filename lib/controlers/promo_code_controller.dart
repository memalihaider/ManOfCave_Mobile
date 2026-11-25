// controllers/promo_code_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/promo_code_model.dart';
import '../utils/safe_firestore.dart';

class PromoCodeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<PromoCodeModel> _promoCodes = <PromoCodeModel>[].obs;
  final RxList<PromoCodeModel> _activePromoCodes = <PromoCodeModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  List<PromoCodeModel> get promoCodes => _promoCodes;
  List<PromoCodeModel> get activePromoCodes => _activePromoCodes;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    print('🚀 PromoCodeController initialized');
    
    // We don't automatically load promo codes here to avoid startup noisy errors
    // Instead, they are loaded by screens that need them (like Checkout)
    // or when the data is initialized in Home Screen.
  }

  // Load all promo codes
  Future<void> loadPromoCodes() async {
    if (_isLoading.value) return;
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final query = _firestore
          .collection('promoCodes')
          .orderBy('createdAt', descending: true)
          .limit(30);

      void apply(QuerySnapshot<Map<String, dynamic>> snap) {
        final loadedPromoCodes = snap.docs
            .map((doc) => PromoCodeModel.fromFirestore(doc))
            .toList();
        _promoCodes.assignAll(loadedPromoCodes);
        _filterActivePromoCodes();
      }

      final querySnapshot = await SafeFirestore.getQuery(
        query,
        onCache: apply,
      );
      apply(querySnapshot);
    } catch (e) {
      // Guests / missing rules often fail here — keep silent on home.
      _errorMessage.value = 'Failed to load promo codes: $e';
      print('❌ loadPromoCodes: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Filter active promo codes
  void _filterActivePromoCodes() {
    final now = DateTime.now();
    print('🔍 Filtering active promo codes at: $now');

    final active = _promoCodes.where((code) {
      final isValid = code.isValid;
      print('   - ${code.code}: isValid=$isValid');
      return isValid;
    }).toList();

    _activePromoCodes.value = active;
    print('✅ Found ${_activePromoCodes.length} active promo codes out of ${_promoCodes.length}');

    // Print active promo codes summary
    if (_activePromoCodes.isNotEmpty) {
      print('📋 Active promo codes:');
      for (final promo in _activePromoCodes) {
        print('   - ${promo.code}: ${promo.discountDisplay} (valid until: ${promo.validTo})');
      }
    } else {
      print('⚠️ No active promo codes found');
    }
  }

  // Get promo code by ID
  Future<PromoCodeModel?> getPromoCodeById(String id) async {
    try {
      print('🔍 Fetching promo code by ID: $id');
      final doc = await _firestore.collection('promoCodes').doc(id).get();

      if (doc.exists) {
        print('✅ Found promo code with ID: $id');
        final promo = PromoCodeModel.fromFirestore(doc);
        promo.debugPrint();
        return promo;
      } else {
        print('⚠️ No promo code found with ID: $id');
        return null;
      }
    } catch (e) {
      print('❌ Error getting promo code by ID: $e');
      return null;
    }
  }

  // Get promo code by code string
  Future<PromoCodeModel?> getPromoCodeByCode(String code) async {
    try {
      print('🔍 Searching for promo code by code: "$code"');

      final query = await _firestore
          .collection('promoCodes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        print('✅ Found promo code: $code');
        final promo = PromoCodeModel.fromFirestore(query.docs.first);
        promo.debugPrint();
        return promo;
      } else {
        print('⚠️ No promo code found with code: "$code"');
        return null;
      }
    } catch (e) {
      print('❌ Error getting promo code by code: $e');
      return null;
    }
  }

  // Validate promo code for a specific branch and amount
  Future<Map<String, dynamic>> validatePromoCode({
    required String code,
    required String branchId,
    required double amount,
  }) async {
    print('🎯 Validating promo code: "$code"');
    print('   - Branch ID: $branchId');
    print('   - Order amount: $amount');

    try {
      final promo = await getPromoCodeByCode(code);

      if (promo == null) {
        print('❌ Validation failed: Promo code not found');
        return {
          'valid': false,
          'message': 'Invalid promo code',
        };
      }

      print('📋 Found promo: ${promo.code} (${promo.discountDisplay})');

      // Check if promo is active
      if (!promo.isActive) {
        print('❌ Validation failed: Promo code is inactive (status: ${promo.status})');
        return {
          'valid': false,
          'message': 'Promo code is inactive',
        };
      }

      // Check expiration
      final now = DateTime.now();
      if (promo.validTo.isBefore(now)) {
        print('❌ Validation failed: Promo code expired on ${promo.validTo}');
        return {
          'valid': false,
          'message': 'Promo code has expired',
        };
      }

      if (promo.validFrom.isAfter(now)) {
        print('❌ Validation failed: Promo code not yet valid (starts ${promo.validFrom})');
        return {
          'valid': false,
          'message': 'Promo code is not yet valid',
        };
      }

      // Check usage limit
      if (promo.isUsageLimitReached) {
        print('❌ Validation failed: Usage limit reached (${promo.usedCount}/${promo.usageLimit})');
        return {
          'valid': false,
          'message': 'Promo code usage limit reached',
        };
      }

      // Check branch applicability
      if (!promo.isApplicableToBranch(branchId)) {
        print('❌ Validation failed: Promo code not applicable to branch $branchId');
        print('   - Available branches: ${promo.branches}');
        return {
          'valid': false,
          'message': 'Promo code not applicable at this branch',
        };
      }

      // Check minimum purchase
      if (promo.minimumPurchase != null && amount < promo.minimumPurchase!) {
        print('❌ Validation failed: Minimum purchase requirement not met');
        print('   - Required: ${promo.minimumPurchase}');
        print('   - Current: $amount');
        return {
          'valid': false,
          'message': 'Minimum purchase of د.إ${promo.minimumPurchase!.toStringAsFixed(0)} required',
        };
      }

      // Calculate discount
      final discount = promo.calculateDiscount(amount);
      final finalAmount = amount - discount;

      print('✅ Promo code validation successful!');
      print('   - Discount: $discount');
      print('   - Final amount: $finalAmount');

      return {
        'valid': true,
        'promo': promo,
        'discount': discount,
        'finalAmount': finalAmount,
        'message': 'Promo code applied successfully',
      };
    } catch (e) {
      print('❌ Error validating promo code: $e');
      return {
        'valid': false,
        'message': 'Error validating promo code',
      };
    }
  }

  // Increment usage count when promo code is used
  Future<void> incrementUsageCount(String promoId) async {
    try {
      print('📈 Incrementing usage count for promo ID: $promoId');

      await _firestore.collection('promoCodes').doc(promoId).update({
        'usedCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      final index = _promoCodes.indexWhere((p) => p.id == promoId);
      if (index != -1) {
        final updatedPromo = _promoCodes[index].copyWith(
          usedCount: _promoCodes[index].usedCount + 1,
        );
        _promoCodes[index] = updatedPromo;
        print('✅ Updated local promo code: ${updatedPromo.code} (used: ${updatedPromo.usedCount})');
      }

      _filterActivePromoCodes();

    } catch (e) {
      print('❌ Error incrementing usage count: $e');
    }
  }

  // Get promos for a specific branch
  List<PromoCodeModel> getPromosForBranch(String branchId) {
    print('🔍 Getting promos for branch: $branchId');
    final promos = _activePromoCodes
        .where((promo) => promo.isApplicableToBranch(branchId))
        .toList();

    print('📋 Found ${promos.length} promos for branch $branchId');
    for (final promo in promos) {
      print('   - ${promo.code}: ${promo.discountDisplay}');
    }

    return promos;
  }

  // Get promos for a branch by name
  List<PromoCodeModel> getPromosForBranchName(String branchName) {
    print('🔍 Getting promos for branch name: $branchName');
    final promos = _activePromoCodes
        .where((promo) => promo.isApplicableToBranchName(branchName))
        .toList();

    print('📋 Found ${promos.length} promos for branch $branchName');
    for (final promo in promos) {
      print('   - ${promo.code}: ${promo.discountDisplay}');
    }

    return promos;
  }

  // Check if a promo code exists and is valid for a branch
  Future<bool> isPromoValidForBranch({
    required String code,
    required String branchId,
  }) async {
    print('🔍 Checking if promo $code is valid for branch $branchId');

    try {
      final promo = await getPromoCodeByCode(code);

      if (promo == null) {
        print('❌ Promo code not found');
        return false;
      }

      if (!promo.isValid) {
        print('❌ Promo code is not valid');
        return false;
      }

      final isValid = promo.isApplicableToBranch(branchId);
      print('✅ Promo code validity: $isValid');
      return isValid;

    } catch (e) {
      print('❌ Error checking promo validity: $e');
      return false;
    }
  }

  // Get promo code statistics
  Map<String, dynamic> getPromoStats() {
    print('📊 Calculating promo code statistics...');

    final stats = {
      'total': _promoCodes.length,
      'active': _activePromoCodes.length,
      'expired': _promoCodes.where((p) => !p.isValid && p.validTo.isBefore(DateTime.now())).length,
      'inactive': _promoCodes.where((p) => !p.isActive).length,
      'usageLimitReached': _promoCodes.where((p) => p.isUsageLimitReached).length,
      'byDiscountType': {
        'percentage': _promoCodes.where((p) => p.discountType == 'percentage').length,
        'fixed': _promoCodes.where((p) => p.discountType == 'fixed').length,
      },
    };

    print('📊 Promo Stats:');
    print('   - Total: ${stats['total']}');
    print('   - Active: ${stats['active']}');
    print('   - Expired: ${stats['expired']}');
    print('   - Inactive: ${stats['inactive']}');
    print('   - Usage limit reached: ${stats['usageLimitReached']}');

    return stats;
  }

  // Refresh promo codes
  Future<void> refreshPromoCodes() async {
    print('🔄 Refreshing promo codes...');
    await loadPromoCodes();
  }

  // Debug method to print all promo codes
  void debugPrintAllPromos() {
    print('\n========== ALL PROMO CODES ==========');
    print('Total: ${_promoCodes.length}');
    for (final promo in _promoCodes) {
      promo.debugPrint();
    }
    print('======================================\n');
  }

  // Clear error message
  void clearError() {
    _errorMessage.value = '';
  }
}