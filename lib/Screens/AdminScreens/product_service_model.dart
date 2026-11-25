// class Category {
//   final String id;
//   final String name;
//   final String type; // 'service' or 'product'
//   final String? icon;
//
//   Category({
//     required this.id,
//     required this.name,
//     required this.type,
//     this.icon,
//   });
// }
//
// class Product {
//   final String id;
//   final String name;
//   final String description;
//   final String categoryId;
//   final double price;
//   final double cost;
//   final int stock;
//   final String sku;
//   final List<String> images;
//   final bool isActive;
//   final String? internalNotes;
//   final DateTime createdAt;
//   final DateTime? updatedAt;
//
//   Product({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.categoryId,
//     required this.price,
//     required this.cost,
//     required this.stock,
//     required this.sku,
//     required this.images,
//     required this.isActive,
//     this.internalNotes,
//     required this.createdAt,
//     this.updatedAt,
//   });
//
//   factory Product.fromJson(Map<String, dynamic> json) {
//     return Product(
//       id: json['id'],
//       name: json['name'],
//       description: json['description'],
//       categoryId: json['categoryId'],
//       price: json['price']?.toDouble() ?? 0.0,
//       cost: json['cost']?.toDouble() ?? 0.0,
//       stock: json['stock'] ?? 0,
//       sku: json['sku'],
//       images: List<String>.from(json['images'] ?? []),
//       isActive: json['isActive'] ?? true,
//       internalNotes: json['internalNotes'],
//       createdAt: DateTime.parse(json['createdAt']),
//       updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
//     );
//   }
// }
//
// class Service {
//   final String id;
//   final String name;
//   final String description;
//   final String categoryId;
//   final double price;
//   final int duration; // in minutes
//   final List<String> images;
//   final bool isActive;
//   final String? roomId;
//   final bool requiresRoom;
//   final String? internalNotes;
//   final DateTime createdAt;
//   final DateTime? updatedAt;
//
//   Service({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.categoryId,
//     required this.price,
//     required this.duration,
//     required this.images,
//     required this.isActive,
//     this.roomId,
//     this.requiresRoom = false,
//     this.internalNotes,
//     required this.createdAt,
//     this.updatedAt,
//   });
//
//   factory Service.fromJson(Map<String, dynamic> json) {
//     return Service(
//       id: json['id'],
//       name: json['name'],
//       description: json['description'],
//       categoryId: json['categoryId'],
//       price: json['price']?.toDouble() ?? 0.0,
//       duration: json['duration'] ?? 30,
//       images: List<String>.from(json['images'] ?? []),
//       isActive: json['isActive'] ?? true,
//       roomId: json['roomId'],
//       requiresRoom: json['requiresRoom'] ?? false,
//       internalNotes: json['internalNotes'],
//       createdAt: DateTime.parse(json['createdAt']),
//       updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
//     );
//   }
// }
//
// class Room {
//   final String id;
//   final String name;
//   final String? description;
//   final bool isActive;
//
//   Room({
//     required this.id,
//     required this.name,
//     required this.isActive,
//     this.description,
//   });
// }