// import 'dart:developer';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:jam_beauty_lounge/Screens/AdminScreens/product_service_model.dart';
//
// import '../../models/product_model.dart' hide Product;
//
//
// class ProductServiceController extends GetxController {
//   // Reactive lists
//   var products = <Product>[].obs;
//   var services = <Service>[].obs;
//   var categories = <Category>[].obs;
//   var rooms = <Room>[].obs;
//
//   // Reactive variables for UI state
//   var selectedTab = 0.obs; // 0: Products, 1: Services
//   var searchQuery = ''.obs;
//   var isLoading = false.obs;
//   var selectedCategory = 'All'.obs;
//   var selectedStatus = 'All'.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     loadInitialData();
//   }
//
//   void loadInitialData() {
//     isLoading.value = true;
//
//     // Simulate API delay
//     Future.delayed(const Duration(milliseconds: 500), () {
//       // Load categories
//       categories.assignAll([
//         Category(id: '1', name: 'Hair Services', type: 'service', icon: '✂️'),
//         Category(id: '2', name: 'Beard Services', type: 'service', icon: '🧔'),
//         Category(id: '3', name: 'Spa Services', type: 'service', icon: '🧖'),
//         Category(id: '4', name: 'Hair Products', type: 'product', icon: '🧴'),
//         Category(id: '5', name: 'Beard Products', type: 'product', icon: '🧔‍♂️'),
//         Category(id: '6', name: 'Skincare', type: 'product', icon: '🧼'),
//       ]);
//
//       // Load rooms
//       rooms.assignAll([
//         Room(id: '1', name: 'Room A', isActive: true),
//         Room(id: '2', name: 'Room B', isActive: true),
//         Room(id: '3', name: 'VIP Room', isActive: true),
//       ]);
//
//       // Load sample products
//       products.assignAll([
//         Product(
//           id: '1',
//           name: 'Hair Shampoo',
//           description: 'Professional hair shampoo for all hair types',
//           categoryId: '4',
//           price: 25.99,
//           cost: 12.50,
//           stock: 45,
//           sku: 'HS001',
//           images: ['https://example.com/shampoo.jpg'],
//           isActive: true,
//           internalNotes: 'Best seller product',
//           createdAt: DateTime(2024, 1, 15),
//           updatedAt: DateTime(2024, 11, 20),
//         ),
//         Product(
//           id: '2',
//           name: 'Beard Oil',
//           description: 'Premium beard oil for grooming and conditioning',
//           categoryId: '5',
//           price: 19.99,
//           cost: 8.75,
//           stock: 28,
//           sku: 'BO001',
//           images: ['https://example.com/beard-oil.jpg'],
//           isActive: true,
//           createdAt: DateTime(2024, 2, 10),
//           updatedAt: DateTime(2024, 11, 15),
//         ),
//         Product(
//           id: '3',
//           name: 'Face Cream',
//           description: 'Moisturizing face cream with SPF 30',
//           categoryId: '6',
//           price: 34.99,
//           cost: 15.25,
//           stock: 15,
//           sku: 'FC001',
//           images: ['https://example.com/face-cream.jpg'],
//           isActive: false,
//           internalNotes: 'Low stock, reorder soon',
//           createdAt: DateTime(2024, 3, 5),
//         ),
//       ]);
//
//       // Load sample services
//       services.assignAll([
//         Service(
//           id: '1',
//           name: 'Classic Haircut',
//           description: 'Professional haircut with styling',
//           categoryId: '1',
//           price: 35.00,
//           duration: 30,
//           images: ['https://example.com/haircut.jpg'],
//           isActive: true,
//           requiresRoom: true,
//           roomId: '1',
//           internalNotes: 'Most popular service',
//           createdAt: DateTime(2024, 1, 10),
//           updatedAt: DateTime(2024, 11, 25),
//         ),
//         Service(
//           id: '2',
//           name: 'Beard Trim & Grooming',
//           description: 'Complete beard trimming and grooming service',
//           categoryId: '2',
//           price: 25.00,
//           duration: 20,
//           images: ['https://example.com/beard-trim.jpg'],
//           isActive: true,
//           requiresRoom: true,
//           roomId: '2',
//           createdAt: DateTime(2024, 2, 15),
//         ),
//         Service(
//           id: '3',
//           name: 'Full Body Massage',
//           description: 'Relaxing full body massage therapy',
//           categoryId: '3',
//           price: 75.00,
//           duration: 60,
//           images: ['https://example.com/massage.jpg'],
//           isActive: false,
//           requiresRoom: true,
//           roomId: '3',
//           internalNotes: 'Under maintenance',
//           createdAt: DateTime(2024, 3, 20),
//         ),
//       ]);
//
//       isLoading.value = false;
//     });
//   }
//
//   // Get filtered products based on search and filters
//   List<Product> get filteredProducts {
//     var filtered = products;
//
//     // Apply search filter
//     if (searchQuery.isNotEmpty) {
//       filtered = filtered.where((product) =>
//       product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
//           product.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
//           product.sku.toLowerCase().contains(searchQuery.toLowerCase())).toList().obs;
//     }
//
//     // Apply category filter
//     if (selectedCategory.value != 'All') {
//       filtered = filtered.where((product) {
//         final category = categories.firstWhereOrNull((cat) => cat.id == product.categoryId);
//         return category?.name == selectedCategory.value;
//       }).toList().obs;
//     }
//
//     // Apply status filter
//     if (selectedStatus.value != 'All') {
//       filtered = filtered.where((product) {
//         if (selectedStatus.value == 'Active') return product.isActive;
//         if (selectedStatus.value == 'Inactive') return !product.isActive;
//         return true;
//       }).toList().obs;
//     }
//
//     return filtered;
//   }
//
//   // Get filtered services based on search and filters
//   List<Service> get filteredServices {
//     var filtered = services;
//
//     // Apply search filter
//     if (searchQuery.isNotEmpty) {
//       filtered = filtered.where((service) =>
//       service.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
//           service.description.toLowerCase().contains(searchQuery.toLowerCase())).toList().obs;
//     }
//
//     // Apply category filter
//     if (selectedCategory.value != 'All') {
//       filtered = filtered.where((service) {
//         final category = categories.firstWhereOrNull((cat) => cat.id == service.categoryId);
//         return category?.name == selectedCategory.value;
//       }).toList().obs;
//     }
//
//     // Apply status filter
//     if (selectedStatus.value != 'All') {
//       filtered = filtered.where((service) {
//         if (selectedStatus.value == 'Active') return service.isActive;
//         if (selectedStatus.value == 'Inactive') return !service.isActive;
//         return true;
//       }).toList().obs;
//     }
//
//     return filtered;
//   }
//
//   // Get categories for current tab
//   List<String> get availableCategories {
//     final type = selectedTab.value == 0 ? 'product' : 'service';
//     return ['All', ...categories.where((cat) => cat.type == type).map((cat) => cat.name).toList()];
//   }
//
//   // Switch between products and services
//   void switchTab(int index) {
//     selectedTab.value = index;
//     selectedCategory.value = 'All';
//     selectedStatus.value = 'All';
//     searchQuery.value = '';
//   }
//
//   // Search function
//   void search(String query) {
//     searchQuery.value = query;
//   }
//
//   // Add new product
//   void addProduct(Product product) {
//     products.insert(0, product);
//     Get.back();
//     Get.snackbar(
//       'Success',
//       'Product added successfully',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Get.theme.primaryColor,
//       colorText: Colors.white,
//     );
//   }
//
//   // Add new service
//   void addService(Service service) {
//     services.insert(0, service);
//     Get.back();
//     Get.snackbar(
//       'Success',
//       'Service added successfully',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Get.theme.primaryColor,
//       colorText: Colors.white,
//     );
//   }
//
//   // Update product
//   void updateProduct(String productId, Product updatedProduct) {
//     final index = products.indexWhere((p) => p.id == productId);
//     if (index != -1) {
//       products[index] = updatedProduct;
//       products.refresh();
//     }
//   }
//
//   // Update service
//   void updateService(String serviceId, Service updatedService) {
//     final index = services.indexWhere((s) => s.id == serviceId);
//     if (index != -1) {
//       services[index] = updatedService;
//       services.refresh();
//     }
//   }
//
//   // Toggle product status
//   void toggleProductStatus(String productId) {
//     final index = products.indexWhere((p) => p.id == productId);
//     if (index != -1) {
//       products[index] = products[index].copyWith(isActive: !products[index].isActive);
//       products.refresh();
//     }
//   }
//
//   // Toggle service status
//   void toggleServiceStatus(String serviceId) {
//     final index = services.indexWhere((s) => s.id == serviceId);
//     if (index != -1) {
//       services[index] = services[index].copyWith(isActive: !services[index].isActive);
//       services.refresh();
//     }
//   }
//
//   // Delete product
//   void deleteProduct(String productId) {
//     products.removeWhere((p) => p.id == productId);
//   }
//
//   // Delete service
//   void deleteService(String serviceId) {
//     services.removeWhere((s) => s.id == serviceId);
//   }
//
//   // Get product categories
//   List<Category> get productCategories {
//     return categories.where((cat) => cat.type == 'product').toList();
//   }
//
//   // Get service categories
//   List<Category> get serviceCategories {
//     return categories.where((cat) => cat.type == 'service').toList();
//   }
//
//   // Refresh data
//   void refreshData() {
//     loadInitialData();
//   }
//
//   // Statistics getters
//   int get totalProducts => products.length;
//   int get activeProducts => products.where((p) => p.isActive).length;
//   int get totalServices => services.length;
//   int get activeServices => services.where((s) => s.isActive).length;
//   double get totalProductValue {
//     return products.fold(0, (sum, product) => sum + (product.price * product.stock));
//   }
// }
//
// // Extension methods for copying objects with updated values
// extension ProductCopyWith on Product {
//   Product copyWith({
//     String? id,
//     String? name,
//     String? description,
//     String? categoryId,
//     double? price,
//     double? cost,
//     int? stock,
//     String? sku,
//     List<String>? images,
//     bool? isActive,
//     String? internalNotes,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   }) {
//     return Product(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       description: description ?? this.description,
//       categoryId: categoryId ?? this.categoryId,
//       price: price ?? this.price,
//       cost: cost ?? this.cost,
//       stock: stock ?? this.stock,
//       sku: sku ?? this.sku,
//       images: images ?? this.images,
//       isActive: isActive ?? this.isActive,
//       internalNotes: internalNotes ?? this.internalNotes,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }
// }
//
// extension ServiceCopyWith on Service {
//   Service copyWith({
//     String? id,
//     String? name,
//     String? description,
//     String? categoryId,
//     double? price,
//     int? duration,
//     List<String>? images,
//     bool? isActive,
//     String? roomId,
//     bool? requiresRoom,
//     String? internalNotes,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   }) {
//     return Service(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       description: description ?? this.description,
//       categoryId: categoryId ?? this.categoryId,
//       price: price ?? this.price,
//       duration: duration ?? this.duration,
//       images: images ?? this.images,
//       isActive: isActive ?? this.isActive,
//       roomId: roomId ?? this.roomId,
//       requiresRoom: requiresRoom ?? this.requiresRoom,
//       internalNotes: internalNotes ?? this.internalNotes,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }
// }