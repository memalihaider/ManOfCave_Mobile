import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controlers/auth_controller.dart';
import '../../controlers/chat_controller.dart';
import '../../models/chat_message_model.dart';
import '../../models/chat_room_model.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;

  const ChatRoomScreen({super.key, required this.roomId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final RxBool _isTyping = false.obs;
  final RxList<String> _typingUsers = <String>[].obs;
  final RxBool _showSendButton = false.obs;
  final RxString _replyToMessageId = RxString('');
  final RxString _replyToContent = RxString('');

  @override
  void initState() {
    super.initState();
    _loadRoom();
    _setupTypingListener();
    _focusNode.addListener(_onFocusChange);
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _chatController.sendTypingIndicator(widget.roomId, false);
    _focusNode.removeListener(_onFocusChange);
    _messageController.removeListener(_onMessageChanged);
    _focusNode.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadRoom() async {
    ChatRoom? foundRoom;
    for (var room in _chatController.chatRooms) {
      if (room.roomId == widget.roomId) {
        foundRoom = room;
        break;
      }
    }

    if (foundRoom != null) {
      await _chatController.selectRoom(foundRoom);
    }
  }

  void _setupTypingListener() {
    _chatController.getTypingUsers(widget.roomId).listen((users) {
      _typingUsers.value = users.where((id) => id != _chatController.currentUserId).toList();
    });
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _chatController.sendTypingIndicator(widget.roomId, true);
    } else {
      _chatController.sendTypingIndicator(widget.roomId, false);
    }
  }

  void _onMessageChanged() {
    final text = _messageController.text.trim();
    _showSendButton.value = text.isNotEmpty;
    _isTyping.value = text.isNotEmpty;
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (_replyToMessageId.value.isNotEmpty) {
      _chatController.sendTextMessage(
        roomId: widget.roomId,
        content: message,
        replyToMessageId: _replyToMessageId.value,
        replyToContent: _replyToContent.value,
      );
      _clearReply();
    } else {
      _chatController.sendTextMessage(
        roomId: widget.roomId,
        content: message,
      );
    }

    _messageController.clear();
    _showSendButton.value = false;
    _isTyping.value = false;
    _scrollToBottom();
    _chatController.sendTypingIndicator(widget.roomId, false);
  }

  void _clearReply() {
    _replyToMessageId.value = '';
    _replyToContent.value = '';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getRoomDisplayName(ChatRoom? room) {
    if (room == null) return 'Chat';

    if (_authController.isCustomer) {
      if (room.branchName != null && room.branchName!.isNotEmpty) {
        return room.branchName!;
      }
      final otherParticipant = room.getOtherParticipantName(_chatController.currentUserId);
      return otherParticipant != 'Unknown' ? otherParticipant : 'Branch Admin';
    } else if (_authController.isBranchAdmin) {
      if (room.roomType == 'customer_branch') {
        return room.customerName ?? room.getOtherParticipantName(_chatController.currentUserId);
      } else if (room.roomType == 'branch_super') {
        return 'Super Admin';
      }
    } else if (_authController.isSuperAdmin) {
      if (room.roomType == 'branch_super') {
        return room.branchName ?? room.getOtherParticipantName(_chatController.currentUserId);
      }
    }
    return room.displayName;
  }

  String _getSenderDisplayName(ChatMessage message) {
    final isCurrentUser = message.senderId == _chatController.currentUserId;
    if (isCurrentUser) return 'You';

    if (message.senderRole == 'super_admin') return 'Super Admin';
    if (message.senderRole == 'admin' || message.senderRole == 'branch_admin') return 'Admin';
    return message.senderName;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showMessageOptions(ChatMessage message) {
    final isCurrentUser = message.senderId == _chatController.currentUserId;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLarge20),
          ),
        ),
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.width(40),
              height: AppSizes.height(4),
              margin: EdgeInsets.only(bottom: AppSizes.spaceMedium16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
              ),
            ),
            ListTile(
              leading: Container(
                padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.reply,
                  color: AppColors.primaryGold,
                  size: AppSizes.icon(20),
                ),
              ),
              title: Text(
                'Reply',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Get.back();
                _replyToMessageId.value = message.messageId;
                _replyToContent.value = message.content;
                _focusNode.requestFocus();
              },
            ),
            ListTile(
              leading: Container(
                padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.copy,
                  color: Colors.blue,
                  size: AppSizes.icon(20),
                ),
              ),
              title: Text(
                'Copy',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Get.back();
                _chatController.copyMessage(message.content);
                Get.snackbar(
                  'Copied',
                  'Message copied to clipboard',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              },
            ),
            if (isCurrentUser && !message.isDeleted)
              ListTile(
                leading: Container(
                  padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: AppSizes.icon(20),
                  ),
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Get.back();
                  _showDeleteConfirmation(message);
                },
              ),
            if (isCurrentUser && !message.isDeleted && message.isText)
              ListTile(
                leading: Container(
                  padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.orange,
                    size: AppSizes.icon(20),
                  ),
                ),
                title: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
                onTap: () {
                  Get.back();
                  _showEditDialog(message);
                },
              ),
            SizedBox(height: AppSizes.spaceSmall8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceSmall8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ChatMessage message) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        ),
        title: Text(
          'Delete Message',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this message?',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _chatController.deleteMessage(widget.roomId, message.messageId);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
            ),
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(ChatMessage message) {
    final editController = TextEditingController(text: message.content);

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        ),
        title: Text(
          'Edit Message',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          child: TextField(
            controller: editController,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                _chatController.editMessage(
                  widget.roomId,
                  message.messageId,
                  editController.text.trim(),
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
            ),
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Obx(() {
          final room = _chatController.selectedRoom;
          final displayName = _getRoomDisplayName(room);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_typingUsers.isNotEmpty)
                Text(
                  'typing...',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
            ],
          );
        }),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showRoomInfo,
            tooltip: 'Chat Info',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Obx(() => _replyToMessageId.value.isNotEmpty
                ? _buildReplyPreview()
                : const SizedBox.shrink()),
            Obx(() => _chatController.isUploading
                ? _buildUploadProgress()
                : const SizedBox.shrink()),
            Expanded(
              child: Obx(() {
                final messages = _chatController.getMessages(widget.roomId);
                final filteredMessages = messages.where((msg) => !msg.isSystem).toList();

                if (_chatController.isLoading && filteredMessages.isEmpty) {
                  return _buildLoadingState();
                }

                if (filteredMessages.isEmpty) {
                  return _buildEmptyChat();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) {
                    final message = filteredMessages[index];
                    return _buildMessageBubble(message);
                  },
                );
              }),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
            ),
            child: Icon(
              Icons.reply,
              size: AppSizes.icon(16),
              color: AppColors.primaryGold,
            ),
          ),
          SizedBox(width: AppSizes.spaceSmall8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying',
                  style: TextStyle(
                    fontSize: AppSizes.font(10),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGold,
                  ),
                ),
                SizedBox(height: AppSizes.height(2)),
                Text(
                  _replyToContent.value.length > 50
                      ? '${_replyToContent.value.substring(0, 50)}...'
                      : _replyToContent.value,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearReply,
            icon: Icon(
              Icons.close,
              size: AppSizes.iconSmall18,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade200),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSizes.width(20),
            height: AppSizes.height(20),
            child: CircularProgressIndicator(
              value: _chatController.uploadProgress / 100,
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          SizedBox(width: AppSizes.spaceSmall8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploading image...',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: AppSizes.height(2)),
                Text(
                  '${_chatController.uploadProgress.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: AppSizes.font(10),
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isCurrentUser = message.senderId == _chatController.currentUserId;
    final senderDisplayName = _getSenderDisplayName(message);

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: AppSizes.height(4)),
        child: Row(
          mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isCurrentUser)
              Padding(
                padding: EdgeInsets.only(right: AppSizes.width(8)),
                child: _buildSenderAvatar(message),
              ),
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: AppSizes.width(280)),
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceSmall8,
                  vertical: AppSizes.spaceSmall8,
                ),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? AppColors.primaryGold
                      : Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusMedium12),
                    topRight: Radius.circular(AppSizes.radiusMedium12),
                    bottomLeft: isCurrentUser
                        ? Radius.circular(AppSizes.radiusMedium12)
                        : Radius.circular(AppSizes.radiusMedium12),
                    bottomRight: isCurrentUser
                        ? Radius.circular(AppSizes.radiusMedium12)
                        : Radius.circular(AppSizes.radiusMedium12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser && !message.isSystem)
                      Text(
                        senderDisplayName,
                        style: TextStyle(
                          fontSize: AppSizes.font(10),
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    if (message.hasReply && !message.isDeleted)
                      _buildMessageReplyPreview(message, isCurrentUser),
                    if (message.isDeleted)
                      _buildDeletedMessage()
                    else if (message.isImage)
                      _buildImageMessage(message, isCurrentUser)
                    else
                      Text(
                        message.content,
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          color: isCurrentUser ? AppColors.white : AppColors.primaryDark,
                        ),
                      ),
                    SizedBox(height: AppSizes.height(4)),
                    _buildMessageStatus(message, isCurrentUser),
                  ],
                ),
              ),
            ),
            if (isCurrentUser)
              SizedBox(width: AppSizes.width(8)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageReplyPreview(ChatMessage message, bool isCurrentUser) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.white.withOpacity(0.2)
            : AppColors.primaryGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
        border: Border.all(
          color: isCurrentUser
              ? Colors.white.withOpacity(0.3)
              : AppColors.primaryGold.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.width(3),
            height: AppSizes.height(30),
            color: AppColors.primaryGold,
          ),
          SizedBox(width: AppSizes.spaceSmall8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying',
                  style: TextStyle(
                    fontSize: AppSizes.font(10),
                    fontWeight: FontWeight.w600,
                    color: isCurrentUser
                        ? Colors.white.withOpacity(0.8)
                        : AppColors.primaryGold,
                  ),
                ),
                SizedBox(height: AppSizes.height(2)),
                Text(
                  message.replyToContent ?? '',
                  style: TextStyle(
                    fontSize: AppSizes.font(11),
                    color: isCurrentUser
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(ChatMessage message, bool isCurrentUser) {
    if (message.metadata?['uploading'] == true) {
      return Container(
        width: AppSizes.width(200),
        height: AppSizes.height(150),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: message.metadata?['uploadProgress']?.toDouble(),
              strokeWidth: 2,
              color: AppColors.primaryGold,
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              'Uploading...',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (message.fileUrl == null || message.fileUrl!.isEmpty) {
      return Container(
        width: AppSizes.width(200),
        height: AppSizes.height(150),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
        ),
        child: Center(
          child: Icon(
            Icons.broken_image,
            size: AppSizes.icon(40),
            color: Colors.grey[500],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showFullScreenImage(message.fileUrl!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
            child: CachedNetworkImage(
              imageUrl: message.fileUrl!,
              width: AppSizes.width(200),
              height: AppSizes.height(150),
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: AppSizes.width(200),
                height: AppSizes.height(150),
                color: Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: AppSizes.width(200),
                height: AppSizes.height(150),
                color: Colors.grey[300],
                child: Icon(
                  Icons.broken_image,
                  size: AppSizes.icon(40),
                  color: Colors.grey[500],
                ),
              ),
            ),
          ),
        ),
        if (message.fileSize != null && message.fileSize! > 0)
          Padding(
            padding: EdgeInsets.only(top: AppSizes.height(4)),
            child: Text(
              _formatFileSize(message.fileSize!),
              style: TextStyle(
                fontSize: AppSizes.font(9),
                color: isCurrentUser
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey[500],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeletedMessage() {
    return Row(
      children: [
        Icon(
          Icons.delete_outline,
          size: AppSizes.icon(14),
          color: Colors.grey[500],
        ),
        SizedBox(width: AppSizes.width(4)),
        Text(
          'This message was deleted',
          style: TextStyle(
            fontSize: AppSizes.textSmall12,
            fontStyle: FontStyle.italic,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageStatus(ChatMessage message, bool isCurrentUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatMessageTime(message.timestamp),
          style: TextStyle(
            fontSize: AppSizes.font(10),
            color: isCurrentUser
                ? AppColors.white.withOpacity(0.7)
                : Colors.grey[500],
          ),
        ),
        if (message.isEdited && !message.isDeleted) ...[
          SizedBox(width: AppSizes.width(4)),
          Text(
            'edited',
            style: TextStyle(
              fontSize: AppSizes.font(9),
              fontStyle: FontStyle.italic,
              color: isCurrentUser
                  ? AppColors.white.withOpacity(0.7)
                  : Colors.grey[500],
            ),
          ),
        ],
        if (isCurrentUser && !message.isDeleted) ...[
          SizedBox(width: AppSizes.width(4)),
          Icon(
            message.isRead
                ? Icons.done_all
                : message.isDelivered
                ? Icons.done_all
                : Icons.done,
            size: AppSizes.icon(12),
            color: message.isRead
                ? Colors.blue
                : message.isDelivered
                ? Colors.blue.shade300
                : Colors.grey,
          ),
        ],
      ],
    );
  }

  Widget _buildSenderAvatar(ChatMessage message) {
    final senderDisplayName = _getSenderDisplayName(message);
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.height(4)),
      child: CircleAvatar(
        radius: AppSizes.radius(16),
        backgroundColor: AppColors.primaryGold.withOpacity(0.1),
        child: Text(
          senderDisplayName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: AppSizes.icon(12),
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGold,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.width(16),
        AppSizes.height(8),
        AppSizes.width(16),
        AppSizes.height(16),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showAttachmentOptions,
            child: Container(
              width: AppSizes.width(40),
              height: AppSizes.height(40),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.attach_file,
                size: AppSizes.icon(20),
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(width: AppSizes.width(8)),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.width(12)),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
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
                      maxLines: 5,
                      minLines: 1,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _sendMessage();
                        }
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: AppSizes.paddingAll(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGold,
                      ),
                      child: Icon(
                        Icons.send,
                        size: AppSizes.icon(20),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLarge20),
          ),
        ),
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.width(40),
              height: AppSizes.height(4),
              margin: EdgeInsets.only(bottom: AppSizes.spaceMedium16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
              ),
            ),
            Text(
              'Send Image',
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Colors.blue,
                  onTap: () {
                    Get.back();
                    _chatController.pickAndSendImage(widget.roomId);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.green,
                  onTap: () {
                    Get.back();
                    _chatController.takeAndSendImage(widget.roomId);
                  },
                ),
              ],
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceSmall8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.width(60),
            height: AppSizes.height(60),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppSizes.icon(30),
              color: color,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.textSmall12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(color: AppColors.primaryGold),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(Icons.error, color: Colors.red, size: AppSizes.icon(40)),
                ),
              ),
            ),
            Positioned(
              top: AppSizes.height(40),
              right: AppSizes.width(20),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: AppSizes.iconMedium24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryGold),
          SizedBox(height: AppSizes.spaceMedium16),
          Text(
            'Loading messages...',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: AppSizes.iconMedium24,
            color: Colors.grey[300],
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          Text(
            'Send your first message to begin chatting',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return DateFormat('hh:mm a').format(timestamp);
    } else {
      return DateFormat('MMM d, hh:mm a').format(timestamp);
    }
  }

  void _showRoomInfo() {
    final room = _chatController.selectedRoom;
    if (room == null) return;

    final roomName = _getRoomDisplayName(room);

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLarge20),
          ),
        ),
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: AppSizes.width(40),
                height: AppSizes.height(4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                ),
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Center(
              child: _buildRoomAvatar(room, roomName),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Text(
              roomName,
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Container(
              padding: AppSizes.paddingSymmetric(
                horizontal: AppSizes.spaceSmall8,
                vertical: AppSizes.height(4),
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
              ),
              child: Text(
                room.roomType.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: AppSizes.spaceLarge24),
            _buildInfoItem(
              label: 'Created',
              value: DateFormat('dd MMM yyyy, hh:mm a').format(room.createdAt),
            ),
            _buildInfoItem(
              label: 'Last Active',
              value: room.formattedLastMessageTime,
            ),
            if (room.customerName != null && !_authController.isCustomer)
              _buildInfoItem(
                label: 'Customer',
                value: room.customerName!,
              ),
            if (room.branchName != null)
              _buildInfoItem(
                label: 'Branch',
                value: room.branchName!,
              ),
            _buildInfoItem(
              label: 'Participants',
              value: '${room.participants.length}',
            ),
            SizedBox(height: AppSizes.spaceLarge24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: Get.back,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.white,
                  padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceSmall8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildRoomAvatar(ChatRoom room, String displayName) {
    return Container(
      width: AppSizes.width(80),
      height: AppSizes.height(80),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGold.withOpacity(0.1),
        border: Border.all(
          color: AppColors.primaryGold,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          displayName.substring(0, 2).toUpperCase(),
          style: TextStyle(
            fontSize: AppSizes.icon(24),
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({required String label, required String value}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.height(8)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}