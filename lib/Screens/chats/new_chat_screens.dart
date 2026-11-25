// screens/chats/new_chat_screens.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controlers/auth_controller.dart';
import '../../controlers/branches_controller.dart';
import '../../controlers/chat_controller.dart';
import '../../controlers/customer_controller.dart';
import '../../controlers/staff_controller.dart';
import '../../models/CustomerModel.dart';
import '../../models/branch_model.dart';
import '../../models/staff.dart';
import '../../models/user_model.dart';
import 'chat_room_screen.dart';

// Main New Chat Screen (role-based)
class NewChatScreen extends StatelessWidget {
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final chatController = Get.find<ChatController>();

    if (chatController.isCustomer) {
      // For customers, go to branch selection screen
      return const NewCustomerBranchSelectionScreen(); // This is where it's called
    } else if (chatController.isBranchAdmin) {
      return const NewBranchAdminChatScreen();
    } else if (chatController.isSuperAdmin) {
      return const NewSuperAdminChatScreen();
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('New Chat'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Text(
            'Chat not available for your role',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }
  }
}

// NEW: Branch Selection Screen for Customers
class NewCustomerBranchSelectionScreen extends StatefulWidget {
  const NewCustomerBranchSelectionScreen({super.key});

  @override
  State<NewCustomerBranchSelectionScreen> createState() => _NewCustomerBranchSelectionScreenState();
}

class _NewCustomerBranchSelectionScreenState extends State<NewCustomerBranchSelectionScreen> {
  final BranchController _branchController = Get.find<BranchController>();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _branchController.loadBranches();
  }

  List<Branch> getFilteredBranches() {
    final branches = _branchController.activeBranches;

    if (_searchQuery.value.isEmpty) return branches;

    return branches.where((branch) {
      return branch.name.toLowerCase().contains(_searchQuery.value.toLowerCase()) ||
          branch.city.toLowerCase().contains(_searchQuery.value.toLowerCase()) ||
          (branch.managerName?.toLowerCase().contains(_searchQuery.value.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Select Branch',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 16.w),
                        Icon(
                          Icons.search,
                          size: 20.sp,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              _searchQuery.value = value;
                            },
                            decoration: InputDecoration(
                              hintText: 'Search branches...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                fontSize: AppSizes.textMedium14,
                                color: Colors.grey[500],
                              ),
                            ),
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        if (_searchQuery.value.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, size: 20.sp),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery.value = '';
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info Banner
          Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20.sp,
                  color: AppColors.primaryGold,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Select a branch to start chatting with their administrator',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Branch List
          Expanded(
            child: Obx(() {
              if (_branchController.isLoading.value) {
                return _buildLoadingState();
              }

              final branches = getFilteredBranches();

              if (branches.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: branches.length,
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  return _buildBranchItem(branch);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchItem(Branch branch) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startChatWithBranch(branch),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branch Icon
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGold.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      branch.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),

                // Branch Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.name,
                        style: TextStyle(
                          fontSize: AppSizes.textLarge18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14.sp,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              '${branch.city}, ${branch.country}',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (branch.managerName != null) ...[
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14.sp,
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Manager: ${branch.managerName}',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: branch.isOpenNow() ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              branch.isOpenNow() ? 'Open Now' : 'Closed',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: branch.isOpenNow() ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Chat',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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

  Future<void> _startChatWithBranch(Branch branch) async {
    try {
      final chatController = Get.find<ChatController>();

      // Get branch admin ID - you need to implement this logic
      // This could come from staff controller or a separate mapping
      final branchAdminId = await _getBranchAdminId(branch.id);
      final branchAdminName = branch.managerName ?? '${branch.name} Admin';

      final room = await chatController.createChatRoom(
        otherUserId: branchAdminId,
        otherUserName: branchAdminName,
        otherUserRole: 'branch_admin',
        branchId: branch.id,
        branchName: branch.name,
        customerId: chatController.currentUserId,
        customerName: chatController.currentUserName,
        roomType: 'customer_branch',
      );

      if (room != null) {
        Get.offAll(
              () => ChatRoomScreen(roomId: room.roomId),
          transition: Transition.rightToLeft,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to create chat room',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<String> _getBranchAdminId(String branchId) async {
    // Implement logic to get branch admin ID
    // This could be from a separate collection mapping branches to admins
    // For now, using a placeholder
    return 'branch_admin_$branchId';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryGold),
          SizedBox(height: 16.h),
          Text(
            'Loading branches...',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 80.sp, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            'No branches available',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _searchQuery.value.isNotEmpty
                ? 'Try a different search'
                : 'No active branches at the moment',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Updated: Screen for Customers to chat with Branch Admin (After Branch Selection)
class NewCustomerToAdminChatScreen extends StatefulWidget {
  final Branch selectedBranch;

  const NewCustomerToAdminChatScreen({
    super.key,
    required this.selectedBranch,
  });

  @override
  State<NewCustomerToAdminChatScreen> createState() => _NewCustomerToAdminChatScreenState();
}

class _NewCustomerToAdminChatScreenState extends State<NewCustomerToAdminChatScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    _startChat();
  }

  Future<void> _startChat() async {
    await _startChatWithBranchAdmin();
  }

  Future<void> _startChatWithBranchAdmin() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // Get branch admin ID (implement based on your data structure)
      final branchAdminId = await _getBranchAdminId(widget.selectedBranch.id);
      final branchAdminName = widget.selectedBranch.managerName ??
          '${widget.selectedBranch.name} Admin';

      final room = await _chatController.createChatRoom(
        otherUserId: branchAdminId,
        otherUserName: branchAdminName,
        otherUserRole: 'branch_admin',
        branchId: widget.selectedBranch.id,
        branchName: widget.selectedBranch.name,
        customerId: _chatController.currentUserId,
        customerName: _chatController.currentUserName,
        roomType: 'customer_branch',
      );

      if (room != null) {
        Get.offAll(
              () => ChatRoomScreen(roomId: room.roomId),
          transition: Transition.rightToLeft,
        );
      } else {
        _errorMessage.value = 'Failed to create chat room';
      }
    } catch (e) {
      _errorMessage.value = 'Error: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<String> _getBranchAdminId(String branchId) async {
    // TODO: Implement actual logic to get branch admin ID
    // This could query staff collection where role = 'branch_admin' and branchId = branchId
    return 'branch_admin_$branchId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Starting Chat',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading.value) ...[
              CircularProgressIndicator(color: AppColors.primaryGold),
              SizedBox(height: 24.h),
              Text(
                'Creating chat with ${widget.selectedBranch.name}...',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey[600],
                ),
              ),
            ] else if (_errorMessage.value.isNotEmpty) ...[
              Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
              SizedBox(height: 16.h),
              Text(
                'Failed to start chat',
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _errorMessage.value,
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// screens/chats/new_chat_screens.dart - Fixed NewBranchAdminChatScreen

// Screen for Branch Admin to chat with Customers and Super Admin
class NewBranchAdminChatScreen extends StatefulWidget {
  const NewBranchAdminChatScreen({super.key});

  @override
  State<NewBranchAdminChatScreen> createState() => _NewBranchAdminChatScreenState();
}

class _NewBranchAdminChatScreenState extends State<NewBranchAdminChatScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();
  final CustomerController _customerController = Get.find<CustomerController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxString _selectedChatType = 'customers'.obs; // 'customers' or 'super_admin'
  final RxList<UserModel> _superAdmins = <UserModel>[].obs;
  final RxBool _isLoadingCustomers = false.obs;
  final RxBool _isLoadingSuperAdmins = false.obs;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCustomers(),
      _loadSuperAdminsFromUsers(),
    ]);
  }

  // Load customers from CustomerController
  Future<void> _loadCustomers() async {
    try {
      _isLoadingCustomers.value = true;

      if (_authController.isBranchAdmin) {
        await _customerController.loadBranchCustomers();
        print("✅ Loaded branch customers: ${_customerController.customers.length}");
      } else {
        await _customerController.loadAllCustomers();
        print("✅ Loaded all customers: ${_customerController.customers.length}");
      }
    } catch (e) {
      print("❌ Error loading customers: $e");
      Get.snackbar(
        'Error',
        'Failed to load customers',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoadingCustomers.value = false;
    }
  }

  // Fetch all super admins from users collection
  Future<void> _loadSuperAdminsFromUsers() async {
    try {
      _isLoadingSuperAdmins.value = true;
      final firestore = FirebaseFirestore.instance;

      final querySnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'super_admin')
          .where('status', isEqualTo: 'active')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final superAdmins = querySnapshot.docs
            .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
            .toList();
        _superAdmins.assignAll(superAdmins);
        print("✅ Loaded ${_superAdmins.length} Super Admins");
      } else {
        print("⚠️ No active super admins found");
        _superAdmins.clear();
      }
    } catch (e) {
      print("❌ Error loading super admins: $e");
    } finally {
      _isLoadingSuperAdmins.value = false;
    }
  }

  List<CustomerModel> getFilteredCustomers() {
    final customers = _customerController.customers
        .where((customer) => customer.isActive && customer.role == 'customer')
        .toList();

    if (_searchQuery.value.isEmpty) return customers;

    final query = _searchQuery.value.toLowerCase();
    return customers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query) ||
          customer.phone.contains(query);
    }).toList();
  }

  List<UserModel> getFilteredSuperAdmins() {
    if (_searchQuery.value.isEmpty) return _superAdmins;

    final query = _searchQuery.value.toLowerCase();
    return _superAdmins.where((admin) {
      return admin.name.toLowerCase().contains(query) ||
          admin.email.toLowerCase().contains(query) ||
          (admin.phone?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'New Chat',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Column(
            children: [
              // Chat Type Selector
              Container(
                padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                color: AppColors.white,
                child: Row(
                  children: [
                    _buildChatTypeChip('Customers', 'customers', isLandscape),
                    SizedBox(width: AppSizes.width(8)),
                    _buildChatTypeChip('Super Admin', 'super_admin', isLandscape),
                  ],
                ),
              ),

              // Search Bar - Using Obx for reactive search
              Obx(() {
                // Show search bar only when there are items to search
                if ((_selectedChatType.value == 'customers' && _customerController.customers.isNotEmpty) ||
                    (_selectedChatType.value == 'super_admin' && _superAdmins.isNotEmpty)) {
                  return _buildSearchBar(isLandscape, _selectedChatType.value);
                }
                return const SizedBox();
              }),

              SizedBox(height: AppSizes.spaceSmall8),

              // List based on selected type - Using Obx for reactive content
              Expanded(
                child: Obx(() {
                  if (_selectedChatType.value == 'customers') {
                    // Loading state
                    if (_isLoadingCustomers.value && _customerController.customers.isEmpty) {
                      return _buildLoadingState('Loading customers...');
                    }

                    final customers = getFilteredCustomers();
                    if (customers.isEmpty) {
                      return _buildEmptyState(
                          'No customers found',
                          _searchQuery.value.isNotEmpty,
                          'customers'
                      );
                    }
                    return ListView.builder(
                      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return _buildCustomerItem(customer);
                      },
                    );
                  } else {
                    // Loading state
                    if (_isLoadingSuperAdmins.value && _superAdmins.isEmpty) {
                      return _buildLoadingState('Loading super admins...');
                    }

                    final superAdmins = getFilteredSuperAdmins();
                    if (superAdmins.isEmpty) {
                      return _buildEmptyState(
                          'No super admins found',
                          _searchQuery.value.isNotEmpty,
                          'super_admin'
                      );
                    }
                    return ListView.builder(
                      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                      itemCount: superAdmins.length,
                      itemBuilder: (context, index) {
                        final superAdmin = superAdmins[index];
                        return _buildSuperAdminItem(superAdmin);
                      },
                    );
                  }
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isLandscape, String type) {
    final hintText = type == 'customers'
        ? (isLandscape ? 'Search customers...' : 'Search customers...')
        : (isLandscape ? 'Search super admins...' : 'Search super admins...');

    return Container(
      padding: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceMedium16),
      color: AppColors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            SizedBox(width: AppSizes.width(16)),
            Icon(
              Icons.search,
              size: isLandscape ? AppSizes.iconSmall18 : AppSizes.icon(20),
              color: Colors.grey[500],
            ),
            SizedBox(width: AppSizes.width(12)),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  _searchQuery.value = value;
                },
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: isLandscape ? AppSizes.textSmall12 : AppSizes.textMedium14,
                    color: Colors.grey[500],
                  ),
                ),
                style: TextStyle(
                  fontSize: isLandscape ? AppSizes.textSmall12 : AppSizes.textMedium14,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            if (_searchQuery.value.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, size: AppSizes.iconSmall18),
                onPressed: () {
                  _searchController.clear();
                  _searchQuery.value = '';
                },
              ),
            SizedBox(width: AppSizes.width(8)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTypeChip(String label, String value, bool isLandscape) {
    return Obx(() {
      final isSelected = _selectedChatType.value == value;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            // Update the selected chat type
            _selectedChatType.value = value;
            // Clear search when switching tabs
            _searchQuery.value = '';
            _searchController.clear();
          },
          child: Container(
            padding: AppSizes.paddingSymmetric(vertical: isLandscape ? AppSizes.height(6) : AppSizes.spaceSmall8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGold : Colors.grey[100],
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              border: Border.all(
                color: isSelected ? AppColors.primaryGold : Colors.grey[300]!,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCustomerItem(CustomerModel customer) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startChatWithCustomer(customer),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          child: Padding(
            padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
            child: Row(
              children: [
                // Avatar
                Container(
                  padding: AppSizes.paddingAll(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      customer.avatarInitials,
                      style: TextStyle(
                        fontSize: AppSizes.icon(18),
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSizes.spaceSmall8),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(height: AppSizes.height(2)),
                      Text(
                        customer.email,
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSizes.height(2)),
                      Text(
                        customer.phone,
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Customer Badge
                Container(
                  padding: AppSizes.paddingSymmetric(
                    horizontal: AppSizes.spaceSmall8,
                    vertical: AppSizes.height(4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    'Customer',
                    style: TextStyle(
                      fontSize: AppSizes.font(10),
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuperAdminItem(UserModel superAdmin) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startChatWithSuperAdmin(superAdmin),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          child: Padding(
            padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: AppSizes.width(50),
                  height: AppSizes.height(50),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purple.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      superAdmin.initials,
                      style: TextStyle(
                        fontSize: AppSizes.icon(18),
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSizes.spaceSmall8),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        superAdmin.name,
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(height: AppSizes.height(2)),
                      Text(
                        superAdmin.email,
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (superAdmin.phone != null && superAdmin.phone!.isNotEmpty) ...[
                        SizedBox(height: AppSizes.height(2)),
                        Text(
                          superAdmin.phone!,
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Super Admin Badge
                Container(
                  padding: AppSizes.paddingSymmetric(
                    horizontal: AppSizes.spaceSmall8,
                    vertical: AppSizes.height(4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                    border: Border.all(color: Colors.purple),
                  ),
                  child: Text(
                    'Super Admin',
                    style: TextStyle(
                      fontSize: AppSizes.font(10),
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startChatWithCustomer(CustomerModel customer) async {
    try {
      final room = await _chatController.createChatRoom(
        otherUserId: customer.uid,
        otherUserName: customer.name,
        otherUserRole: 'customer',
        branchId: _chatController.currentUserBranchId,
        branchName: _chatController.currentUserBranchName,
        customerId: customer.uid,
        customerName: customer.name,
        roomType: 'customer_branch',
      );

      if (room != null) {
        Get.back();
        Get.to(
              () => ChatRoomScreen(roomId: room.roomId),
          transition: Transition.rightToLeft,
        );
      } else {
        _showError('Failed to create chat room');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _startChatWithSuperAdmin(UserModel superAdmin) async {
    try {
      final room = await _chatController.createChatRoom(
        otherUserId: superAdmin.uid,
        otherUserName: superAdmin.name,
        otherUserRole: superAdmin.role,
        branchId: _chatController.currentUserBranchId,
        branchName: _chatController.currentUserBranchName,
        roomType: 'branch_super',
      );

      if (room != null) {
        Get.back();
        Get.to(
              () => ChatRoomScreen(roomId: room.roomId),
          transition: Transition.rightToLeft,
        );
      } else {
        _showError('Failed to create chat room');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryGold),
          SizedBox(height: AppSizes.spaceMedium16),
          Text(
            message,
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isSearching, String type) {
    return Center(
      child: Padding(
        padding: AppSizes.paddingAll(AppSizes.spaceExtraLarge32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'customers'
                  ? (isSearching ? Icons.search_off : Icons.people_outline)
                  : (isSearching ? Icons.search_off : Icons.admin_panel_settings_outlined),
              size: AppSizes.icon(80),
              color: Colors.grey[300],
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Text(
              message,
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            if (isSearching) ...[
              SizedBox(height: AppSizes.spaceSmall8),
              Text(
                'Try a different search term',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (!isSearching && type == 'customers') ...[
              SizedBox(height: AppSizes.spaceSmall8),
              Text(
                'No customers have interacted with your branch yet',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (!isSearching && type == 'super_admin') ...[
              SizedBox(height: AppSizes.spaceSmall8),
              Text(
                'No super admins found in the system',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Screen for Super Admin to chat with Branch Admins
class NewSuperAdminChatScreen extends StatefulWidget {
  const NewSuperAdminChatScreen({super.key});

  @override
  State<NewSuperAdminChatScreen> createState() => _NewSuperAdminChatScreenState();
}

class _NewSuperAdminChatScreenState extends State<NewSuperAdminChatScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();
  final StaffController _staffController = Get.find<StaffController>();
  final BranchController _branchController = Get.find<BranchController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxString _selectedBranchId = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _staffController.loadStaff();
    await _branchController.loadBranches();
  }

  List<Map<String, dynamic>> getBranchAdmins() {
    final admins = <Map<String, dynamic>>[];

    for (final branch in _branchController.activeBranches) {
      // Find staff assigned to this branch with admin role
      final branchStaff = _staffController.allStaff.where((staff) =>
      (staff.role == 'admin' || staff.role == 'branch_admin') &&
          staff.branch == branch.name &&
          staff.isActive
      ).toList();

      if (branchStaff.isNotEmpty) {
        for (final staff in branchStaff) {
          admins.add({
            'staff': staff,
            'branch': branch,
          });
        }
      } else {
        // If no staff found, still show branch with placeholder admin
        admins.add({
          'staff': null,
          'branch': branch,
        });
      }
    }

    // Apply search filter
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      return admins.where((admin) {
        final branch = admin['branch'] as Branch;
        final staff = admin['staff'] as Staff?;

        return branch.name.toLowerCase().contains(query) ||
            branch.city.toLowerCase().contains(query) ||
            (staff?.name.toLowerCase().contains(query) ?? false) ||
            (branch.managerName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return admins;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Chat with Branch Admin',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 16.w),
                        Icon(
                          Icons.search,
                          size: 20.sp,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              _searchQuery.value = value;
                            },
                            decoration: InputDecoration(
                              hintText: 'Search branches or admins...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                fontSize: AppSizes.textMedium14,
                                color: Colors.grey[500],
                              ),
                            ),
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        if (_searchQuery.value.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, size: 20.sp),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery.value = '';
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Branch Admin List
          Expanded(
            child: Obx(() {
              if (_staffController.isLoading.value || _branchController.isLoading.value) {
                return _buildLoadingState();
              }

              final admins = getBranchAdmins();

              if (admins.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: admins.length,
                itemBuilder: (context, index) {
                  final admin = admins[index];
                  final branch = admin['branch'] as Branch;
                  final staff = admin['staff'] as Staff?;
                  return _buildBranchAdminItem(branch, staff);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchAdminItem(Branch branch, Staff? staff) {
    final displayName = staff?.name ?? branch.managerName ?? '${branch.name} Admin';
    final displayRole = staff?.role ?? 'branch_admin';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _startChatWithBranchAdmin(branch, staff, displayName),
        leading: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryGold.withOpacity(0.1),
          ),
          child: Center(
            child: Text(
              branch.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGold,
              ),
            ),
          ),
        ),
        title: Text(
          displayName,
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),
            Text(
              branch.name,
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '${branch.city}, ${branch.country}',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Icon(
          Icons.chat_bubble_outline,
          size: 20.sp,
          color: AppColors.primaryGold,
        ),
      ),
    );
  }

  Future<void> _startChatWithBranchAdmin(Branch branch, Staff? staff, String displayName) async {
    try {
      _isLoading.value = true;

      final adminId = staff?.id ?? 'branch_admin_${branch.id}';
      final adminRole = staff?.role ?? 'branch_admin';

      final room = await _chatController.createChatRoom(
        otherUserId: adminId,
        otherUserName: displayName,
        otherUserRole: adminRole,
        branchId: branch.id,
        branchName: branch.name,
        roomType: 'branch_super',
      );

      if (room != null) {
        Get.back();
        Get.to(
              () => ChatRoomScreen(roomId: room.roomId),
          transition: Transition.rightToLeft,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to create chat room',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryGold),
          SizedBox(height: 16.h),
          Text(
            'Loading branch admins...',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.admin_panel_settings_outlined, size: 80.sp, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            'No branch admins found',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _searchQuery.value.isNotEmpty
                ? 'Try a different search'
                : 'No active branch administrators',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}