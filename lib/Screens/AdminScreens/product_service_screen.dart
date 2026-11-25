// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:man_of_cave/Screens/AdminScreens/product_servicecontroller.dart';
//
// import '../../constants/app_sizes.dart';
// import '../../models/product_model.dart' hide Product;
// import 'add_product.dart';
// import 'add_service.dart';
// import 'product_service_model.dart';
//
// class ProductsServicesScreen extends StatelessWidget {
//   ProductsServicesScreen({super.key});
//
//   final ProductServiceController controller = Get.put(ProductServiceController());
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Get.theme;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Products & Services"),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: controller.refreshData,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Tab Selection
//           Container(
//             decoration: BoxDecoration(
//               color: theme.cardColor,
//               border: Border(
//                 bottom: BorderSide(color: theme.dividerColor),
//               ),
//             ),
//             child: Obx(() => Row(
//               children: [
//                 _buildTabButton(
//                   label: 'Products',
//                   index: 0,
//                   isSelected: controller.selectedTab.value == 0,
//                   theme: theme,
//                 ),
//                 _buildTabButton(
//                   label: 'Services',
//                   index: 1,
//                   isSelected: controller.selectedTab.value == 1,
//                   theme: theme,
//                 ),
//               ],
//             )),
//           ),
//
//           // Statistics Overview
//           Obx(() => Container(
//             padding: AppSizes.paddingAll(16),
//             decoration: BoxDecoration(
//               color: theme.primaryColor.withOpacity(0.05),
//               border: Border(
//                 bottom: BorderSide(color: theme.dividerColor),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: controller.selectedTab.value == 0
//                   ? [
//                 _buildStatItem(
//                   label: 'Total Products',
//                   value: controller.totalProducts.toString(),
//                   color: theme.primaryColor,
//                   theme: theme,
//                 ),
//                 _buildStatItem(
//                   label: 'Active',
//                   value: controller.activeProducts.toString(),
//                   color: Colors.green,
//                   theme: theme,
//                 ),
//                 _buildStatItem(
//                   label: 'Total Value',
//                   value: '\$${controller.totalProductValue.toStringAsFixed(0)}',
//                   color: Colors.blue,
//                   theme: theme,
//                 ),
//               ]
//                   : [
//                 _buildStatItem(
//                   label: 'Total Services',
//                   value: controller.totalServices.toString(),
//                   color: theme.primaryColor,
//                   theme: theme,
//                 ),
//                 _buildStatItem(
//                   label: 'Active',
//                   value: controller.activeServices.toString(),
//                   color: Colors.green,
//                   theme: theme,
//                 ),
//                 _buildStatItem(
//                   label: 'Categories',
//                   value: controller.serviceCategories.length.toString(),
//                   color: Colors.orange,
//                   theme: theme,
//                 ),
//               ],
//             ),
//           )),
//
//           // Search Bar
//           Padding(
//             padding: AppSizes.paddingAll(16),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.1),
//                     blurRadius: 5,
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               child: Obx(() => TextField(
//                 onChanged: controller.search,
//                 decoration: InputDecoration(
//                   hintText: controller.selectedTab.value == 0
//                       ? 'Search products by name, description or SKU...'
//                       : 'Search services by name or description...',
//                   prefixIcon: const Icon(Icons.search),
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 14,
//                   ),
//                 ),
//               )),
//             ),
//           ),
//
//           // Filters
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Obx(() => Row(
//               children: [
//                 // Category Filter
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: theme.dividerColor),
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: controller.selectedCategory.value,
//                         items: controller.availableCategories.map((category) {
//                           return DropdownMenuItem<String>(
//                             value: category,
//                             child: Text(category),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           controller.selectedCategory.value = value!;
//                         },
//                         isExpanded: true,
//                         icon: const Icon(Icons.arrow_drop_down),
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(width: 12),
//
//                 // Status Filter
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: theme.dividerColor),
//                   ),
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton<String>(
//                       value: controller.selectedStatus.value,
//                       items: ['All', 'Active', 'Inactive'].map((status) {
//                         return DropdownMenuItem<String>(
//                           value: status,
//                           child: Text(status),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         controller.selectedStatus.value = value!;
//                       },
//                       icon: const Icon(Icons.filter_list),
//                     ),
//                   ),
//                 ),
//               ],
//             )),
//           ),
//
//           const SizedBox(height: 16),
//
//           // Products/Services List
//           Expanded(
//             child: Obx(() {
//               if (controller.isLoading.value) {
//                 return const Center(
//                   child: CircularProgressIndicator(),
//                 );
//               }
//
//               final isProductsTab = controller.selectedTab.value == 0;
//               final items = isProductsTab
//                   ? controller.filteredProducts
//                   : controller.filteredServices;
//
//               if (items.isEmpty) {
//                 return Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         isProductsTab ? Icons.shopping_bag : Icons.spa,
//                         size: 60,
//                         color: theme.hintColor.withOpacity(0.5),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         controller.searchQuery.isEmpty
//                             ? 'No ${isProductsTab ? 'products' : 'services'} found'
//                             : 'No ${isProductsTab ? 'products' : 'services'} match your search',
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           color: theme.hintColor,
//                         ),
//                       ),
//                       if (controller.searchQuery.isNotEmpty)
//                         TextButton(
//                           onPressed: () {
//                             controller.search('');
//                             controller.selectedCategory.value = 'All';
//                             controller.selectedStatus.value = 'All';
//                           },
//                           child: Text(
//                             'Clear filters',
//                             style: TextStyle(color: theme.primaryColor),
//                           ),
//                         ),
//                     ],
//                   ),
//                 );
//               }
//
//               return RefreshIndicator(
//                 onRefresh: () async {
//                   controller.refreshData();
//                 },
//                 child: ListView.builder(
//                   padding: AppSizes.paddingAll(16),
//                   itemCount: items.length,
//                   itemBuilder: (context, index) {
//                     if (isProductsTab) {
//                       final product = items[index] as Product;
//                       return ProductCard(
//                         product: product,
//                         onEdit: () => _editProduct(product),
//                         onToggleStatus: () => _toggleProductStatus(product.id),
//                         onDelete: () => _deleteProduct(product.id),
//                       );
//                     } else {
//                       final service = items[index] as Service;
//                       return ServiceCard(
//                         service: service,
//                         onEdit: () => _editService(service),
//                         onToggleStatus: () => _toggleServiceStatus(service.id),
//                         onDelete: () => _deleteService(service.id),
//                       );
//                     }
//                   },
//                 ),
//               );
//             }),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           if (controller.selectedTab.value == 0) {
//             Get.to(() => AddProductScreen());
//           } else {
//             Get.to(() => AddServiceScreen());
//           }
//         },
//         backgroundColor: theme.primaryColor,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }
//
//   Widget _buildTabButton({
//     required String label,
//     required int index,
//     required bool isSelected,
//     required ThemeData theme,
//   }) {
//     return Expanded(
//       child: InkWell(
//         onTap: () => controller.switchTab(index),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           decoration: BoxDecoration(
//             color: isSelected ? theme.primaryColor : Colors.transparent,
//             border: Border(
//               bottom: BorderSide(
//                 color: isSelected ? theme.primaryColor : Colors.transparent,
//                 width: 2,
//               ),
//             ),
//           ),
//           child: Center(
//             child: Text(
//               label,
//               style: theme.textTheme.titleMedium?.copyWith(
//                 color: isSelected ? Colors.white : theme.hintColor,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatItem({
//     required String label,
//     required String value,
//     required Color color,
//     required ThemeData theme,
//   }) {
//     return Column(
//       children: [
//         Container(
//           width: 50,
//           height: 50,
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Center(
//             child: Text(
//               value,
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: theme.textTheme.labelSmall?.copyWith(
//             color: theme.hintColor,
//           ),
//         ),
//       ],
//     );
//   }
//
//   void _editProduct(Product product) {
//     Get.to(() => AddProductScreen(product: product));
//   }
//
//   void _editService(Service service) {
//     Get.to(() => AddServiceScreen(service: service));
//   }
//
//   void _toggleProductStatus(String productId) {
//     Get.defaultDialog(
//       title: 'Change Status',
//       middleText: 'Are you sure you want to change the product status?',
//       textConfirm: 'Yes',
//       textCancel: 'No',
//       onConfirm: () {
//         controller.toggleProductStatus(productId);
//         Get.back();
//       },
//     );
//   }
//
//   void _toggleServiceStatus(String serviceId) {
//     Get.defaultDialog(
//       title: 'Change Status',
//       middleText: 'Are you sure you want to change the service status?',
//       textConfirm: 'Yes',
//       textCancel: 'No',
//       onConfirm: () {
//         controller.toggleServiceStatus(serviceId);
//         Get.back();
//       },
//     );
//   }
//
//   void _deleteProduct(String productId) {
//     Get.defaultDialog(
//       title: 'Delete Product',
//       middleText: 'Are you sure you want to delete this product? This action cannot be undone.',
//       textConfirm: 'Delete',
//       textCancel: 'Cancel',
//       confirmTextColor: Colors.white,
//       buttonColor: Colors.red,
//       onConfirm: () {
//         controller.deleteProduct(productId);
//         Get.back();
//         Get.snackbar(
//           'Deleted',
//           'Product has been deleted',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//       },
//     );
//   }
//
//   void _deleteService(String serviceId) {
//     Get.defaultDialog(
//       title: 'Delete Service',
//       middleText: 'Are you sure you want to delete this service? This action cannot be undone.',
//       textConfirm: 'Delete',
//       textCancel: 'Cancel',
//       confirmTextColor: Colors.white,
//       buttonColor: Colors.red,
//       onConfirm: () {
//         controller.deleteService(serviceId);
//         Get.back();
//         Get.snackbar(
//           'Deleted',
//           'Service has been deleted',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//       },
//     );
//   }
// }