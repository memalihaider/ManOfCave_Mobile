import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controlers/auth_controller.dart';
import '../../controlers/chat_controller.dart';
import '../../models/chat_room_model.dart';
import '../../widgets/shimmer_loading.dart';
import 'chat_room_screen.dart';
import 'new_chat_screens.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxString _selectedFilter = 'all'.obs;

  @override
  void initState() {
    super.initState();
    _chatController.ensureListening();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Get filtered rooms based on role
  List<ChatRoom> getFilteredRooms() {
    var rooms = _chatController.chatRooms;

    // Role-based filtering
    if (_authController.isCustomer) {
      rooms = rooms.where((room) => room.roomType == 'customer_branch').toList();
    } else if (_authController.isBranchAdmin) {
      rooms = rooms.where((room) =>
      room.roomType == 'customer_branch' ||
          room.roomType == 'branch_super'
      ).toList();
    }
    // Super admin sees all chat types

    // Apply search
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      rooms = rooms.where((room) {
        final displayName = _getRoomDisplayName(room).toLowerCase();
        final lastMessage = room.lastMessage.toLowerCase();

        return displayName.contains(query) ||
            lastMessage.contains(query) ||
            (room.customerName?.toLowerCase().contains(query) ?? false) ||
            (room.branchName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply filter
    if (_selectedFilter.value != 'all') {
      rooms = rooms.where((room) => room.roomType == _selectedFilter.value).toList();
    }

    return rooms;
  }

  String _getRoomDisplayName(ChatRoom room) {
    if (_authController.isCustomer) {
      // Customers see branch name
      if (room.branchName != null && room.branchName!.isNotEmpty) {
        return room.branchName!;
      }
      final otherParticipant = room.getOtherParticipantName(_chatController.currentUserId);
      return otherParticipant != 'Unknown' ? otherParticipant : 'Branch Admin';
    } else if (_authController.isBranchAdmin) {
      if (room.roomType == 'customer_branch') {
        // Branch admin sees customer name for customer chats
        return room.customerName ?? room.displayName;
      } else if (room.roomType == 'branch_super') {
        // Branch admin sees super admin for those chats
        return 'Super Admin';
      }
    } else if (_authController.isSuperAdmin) {
      if (room.roomType == 'branch_super') {
        // Super admin sees branch name for branch chats
        return room.branchName ?? room.displayName;
      } else if (room.roomType == 'customer_branch') {
        // Super admin sees customer name for customer chats
        return room.customerName ?? room.displayName;
      }
    }
    return room.displayName;
  }

  String _getRoomSubtitle(ChatRoom room) {
    if (room.lastMessage.isEmpty) return 'No messages yet';

    if (room.lastMessage.length > 50) {
      return '${room.lastMessage.substring(0, 50)}...';
    }
    return room.lastMessage;
  }

  List<Map<String, String>> _getAvailableFilters() {
    final filters = <Map<String, String>>[
      {'value': 'all', 'label': 'All'},
    ];

    if (_authController.isCustomer) {
      filters.add({'value': 'customer_branch', 'label': 'Branch Admin'});
    } else if (_authController.isBranchAdmin) {
      filters.addAll([
        {'value': 'customer_branch', 'label': 'Customers'},
        {'value': 'branch_super', 'label': 'Super Admin'},
      ]);
    } else if (_authController.isSuperAdmin) {
      // Super Admin only shows Branch Admins filter
      filters.add({'value': 'branch_super', 'label': 'Branch Admins'});
    }

    return filters;
  }

  Widget? _getRoomTypeBadge(ChatRoom room) {
    Color badgeColor;
    String badgeText;

    if (room.roomType == 'customer_branch') {
      badgeColor = Colors.blue;
      if (_authController.isCustomer) {
        badgeText = 'Admin';
      } else if (_authController.isBranchAdmin) {
        badgeText = 'Customer';
      } else if (_authController.isSuperAdmin) {
        badgeText = 'Customer';
      } else {
        badgeText = 'Chat';
      }
    } else if (room.roomType == 'branch_super') {
      badgeColor = Colors.purple;
      if (_authController.isBranchAdmin) {
        badgeText = 'Super Admin';
      } else if (_authController.isSuperAdmin) {
        badgeText = 'Branch Admin';
      } else {
        badgeText = 'Admin';
      }
    } else {
      badgeColor = Colors.grey;
      badgeText = room.roomType;
    }

    return Container(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceSmall8,
        vertical: AppSizes.height(2),
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: AppSizes.font(10),
          color: badgeColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldSoft,
        foregroundColor: AppColors.textInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: canPop,
        title: Obx(() {
          final totalUnread = _chatController.totalUnreadCount;
          final title = totalUnread > 0 ? 'Chat · $totalUnread' : 'Chat';

          return Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textInk,
              letterSpacing: -0.3,
            ),
          );
        }),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _chatController.refreshChats,
            icon: Icon(Icons.refresh_rounded, color: AppColors.textMuted),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Column(
            children: [
              // Search Bar
              _buildSearchBar(isLandscape),

              // Filters - only show if more than one type
              Obx(() {
                final filters = _getAvailableFilters();
                if (filters.length <= 1) return const SizedBox.shrink();
                return _buildFilterChips(filters, isLandscape);
              }),

              // Chat List
              Expanded(
                child: Obx(() {
                  if (_chatController.isLoading) {
                    return _buildLoadingState();
                  }

                  final rooms = getFilteredRooms();

                  if (rooms.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await _chatController.refreshChats();
                    },
                    child: ListView.separated(
                      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                      itemCount: rooms.length,
                      separatorBuilder: (context, index) => SizedBox(height: AppSizes.spaceSmall8),
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return _buildChatRoomItem(room);
                      },
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSearchBar(bool isLandscape) {
    return Container(
      padding: AppSizes.paddingAll(isLandscape ? AppSizes.spaceSmall8 : AppSizes.spaceMedium16),
      color: AppColors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(color: Colors.grey[200]!),
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
                  hintText: isLandscape ? 'Search...' : 'Search chats...',
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

  Widget _buildFilterChips(List<Map<String, String>> filters, bool isLandscape) {
    return Container(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceMedium16,
        vertical: isLandscape ? AppSizes.spaceSmall8 : AppSizes.spaceSmall8,
      ),
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter.value == filter['value'];
            return Padding(
              padding: EdgeInsets.only(right: AppSizes.width(8)),
              child: FilterChip(
                label: Text(
                  filter['label']!,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: isSelected ? Colors.white : AppColors.primaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primaryGold,
                backgroundColor: Colors.grey[50],
                side: BorderSide(color: Colors.grey[200]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
                ),
                checkmarkColor: Colors.white,
                onSelected: (_) {
                  _selectedFilter.value = filter['value']!;
                },
              ),
            );
          }).toList(),
        )),
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoom room) {
    final unreadCount = _chatController.getUnreadCount(room.roomId);
    final hasUnread = unreadCount > 0;
    final roomName = _getRoomDisplayName(room);
    final roomSubtitle = _getRoomSubtitle(room);
    final badge = _getRoomTypeBadge(room);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
      child: InkWell(
        onTap: () {
          Get.to(
                () => ChatRoomScreen(roomId: room.roomId),
            transition: Transition.rightToLeft,
          );
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        child: Container(
          padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            border: Border.all(
              color: hasUnread
                  ? AppColors.primaryGold.withOpacity(0.3)
                  : Colors.grey[100]!,
              width: hasUnread ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              _buildRoomAvatar(room, roomName, hasUnread),
              SizedBox(width: AppSizes.spaceSmall8),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            roomName,
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                              color: AppColors.primaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          SizedBox(width: AppSizes.width(8)),
                          badge,
                        ],
                      ],
                    ),
                    SizedBox(height: AppSizes.height(4)),
                    Text(
                      roomSubtitle,
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: hasUnread ? AppColors.primaryGold : Colors.grey[600],
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSizes.height(4)),
                    Row(
                      children: [
                        Text(
                          room.formattedLastMessageTime,
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        if (hasUnread)
                          Container(
                            padding: AppSizes.paddingSymmetric(
                              horizontal: AppSizes.spaceSmall8,
                              vertical: AppSizes.height(2),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold,
                              borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: TextStyle(
                                fontSize: AppSizes.font(10),
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildRoomAvatar(ChatRoom room, String name, bool hasUnread) {
    return Stack(
      children: [
        Container(
          width: AppSizes.width(50),
          height: AppSizes.height(50),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryGold.withOpacity(0.1),
            border: Border.all(
              color: hasUnread ? AppColors.primaryGold : Colors.grey[300]!,
              width: hasUnread ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: AppSizes.iconSmall18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGold,
              ),
            ),
          ),
        ),
        if (hasUnread)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: AppSizes.width(12),
              height: AppSizes.height(12),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    if (!_chatController.isAuthenticated) return const SizedBox();

    return FloatingActionButton(
      onPressed: () {
        Get.to(() => const NewChatScreen());
      },
      backgroundColor: AppColors.primaryGold,
      foregroundColor: AppColors.white,
      child: Icon(
        Icons.add_comment,
        size: AppSizes.iconMedium24,
      ),
      tooltip: 'New Chat',
    );
  }

  Widget _buildLoadingState() {
    return ShimmerLoading(
      child: ListView.builder(
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
          child: Container(
            height: 70.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSizes.paddingAll(AppSizes.spaceExtraLarge32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: AppSizes.icon(80),
              color: Colors.grey[300],
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Text(
              'No chats yet',
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              _authController.isCustomer
                  ? 'Start a chat with your branch administrator'
                  : _authController.isBranchAdmin
                  ? 'Start a chat with a customer or super admin'
                  : 'Start a chat with a branch admin',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.spaceLarge24),
            ElevatedButton(
              onPressed: () {
                Get.to(() => const NewChatScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.white,
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceExtraLarge32,
                  vertical: AppSizes.spaceSmall8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                ),
              ),
              child: Text(
                _authController.isCustomer ? 'Start Chat with Branch' : 'Start New Chat',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}