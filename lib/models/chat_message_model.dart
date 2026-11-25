// models/chat_message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum MessageType {
  text,
  image,
  file,
  audio,
  location,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class ChatMessage {
  final String messageId;
  final String roomId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final List<String> readBy;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? replyToMessageId;
  final String? replyToContent;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? editedAt;

  ChatMessage({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.type,
    required this.status,
    required this.readBy,
    required this.timestamp,
    this.metadata,
    this.replyToMessageId,
    this.replyToContent,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.isEdited = false,
    this.isDeleted = false,
    this.editedAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime _parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
      return DateTime.now();
    }

    MessageType _parseMessageType(String type) {
      switch (type) {
        case 'image': return MessageType.image;
        case 'file': return MessageType.file;
        case 'audio': return MessageType.audio;
        case 'location': return MessageType.location;
        case 'system': return MessageType.system;
        default: return MessageType.text;
      }
    }

    MessageStatus _parseMessageStatus(String status) {
      switch (status) {
        case 'sent': return MessageStatus.sent;
        case 'delivered': return MessageStatus.delivered;
        case 'read': return MessageStatus.read;
        case 'failed': return MessageStatus.failed;
        case 'sending': return MessageStatus.sending;
        default: return MessageStatus.sent;
      }
    }

    return ChatMessage(
      messageId: doc.id,
      roomId: data['roomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? 'customer',
      content: data['content'] ?? '',
      type: _parseMessageType(data['type'] ?? 'text'),
      status: _parseMessageStatus(data['status'] ?? 'sent'),
      readBy: List<String>.from(data['readBy'] ?? []),
      timestamp: _parseTimestamp(data['timestamp']),
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
      replyToMessageId: data['replyToMessageId'],
      replyToContent: data['replyToContent'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      isEdited: data['isEdited'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      editedAt: data['editedAt'] != null ? _parseTimestamp(data['editedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'content': content,
      'type': type.name,
      'status': status.name,
      'readBy': readBy,
      'timestamp': Timestamp.fromDate(timestamp),
      if (metadata != null) 'metadata': metadata,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToContent != null) 'replyToContent': replyToContent,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
    };
  }

  // Helper methods
  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isFile => type == MessageType.file;
  bool get isAudio => type == MessageType.audio;
  bool get isSystem => type == MessageType.system;
  bool get isLocation => type == MessageType.location;

  bool get isSent => status == MessageStatus.sent;
  bool get isDelivered => status == MessageStatus.delivered;
  bool get isRead => status == MessageStatus.read;
  bool get isFailed => status == MessageStatus.failed;
  bool get isSending => status == MessageStatus.sending;

  bool get hasReply => replyToMessageId != null && replyToMessageId!.isNotEmpty;

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize} B';
    if (fileSize! < 1048576) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / 1048576).toStringAsFixed(1)} MB';
  }

  IconData get typeIcon {
    switch (type) {
      case MessageType.image:
        return Icons.image;
      case MessageType.file:
        return Icons.insert_drive_file;
      case MessageType.audio:
        return Icons.audiotrack;
      case MessageType.location:
        return Icons.location_on;
      case MessageType.system:
        return Icons.info;
      default:
        return Icons.text_fields;
    }
  }

  Color get statusColor {
    switch (status) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.blue;
      case MessageStatus.delivered:
        return Colors.green;
      case MessageStatus.read:
        return Colors.purple;
      case MessageStatus.failed:
        return Colors.red;
    }
  }

  ChatMessage copyWith({
    String? content,
    MessageStatus? status,
    List<String>? readBy,
    bool? isEdited,
    bool? isDeleted,
    DateTime? editedAt,
    String? fileUrl,
    int? fileSize,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      messageId: messageId,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      content: content ?? this.content,
      type: type,
      status: status ?? this.status,
      readBy: readBy ?? this.readBy,
      timestamp: timestamp,
      metadata: metadata ?? this.metadata,
      replyToMessageId: replyToMessageId,
      replyToContent: replyToContent,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName,
      fileSize: fileSize ?? this.fileSize,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}