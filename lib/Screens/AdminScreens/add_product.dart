// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:jam_beauty_lounge/Screens/AdminScreens/product_service_model.dart';
// import 'package:jam_beauty_lounge/Screens/AdminScreens/product_servicecontroller.dart';
//
// import '../../constants/app_sizes.dart';
//
// class AddProductScreen extends StatefulWidget {
//   final Product? product;
//
//   const AddProductScreen({super.key, this.product});
//
//   @override
//   _AddProductScreenState createState() => _AddProductScreenState();
// }
//
// class _AddProductScreenState extends State<AddProductScreen> {
//   final ProductServiceController controller = Get.find();
//   final _formKey = GlobalKey<FormState>();
//
//   // Form controllers
//   final _nameController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _costController = TextEditingController();
//   final _stockController = TextEditingController();
//   final _skuController = TextEditingController();
//   final _notesController = TextEditingController();
//   final _imageUrlController = TextEditingController();
//
//   String? _selectedCategory;
//   bool _isActive = true;
//   List<String> _images = [];
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Pre-fill form if editing
//     if (widget.product != null) {
//       final product = widget.product!;
//       _nameController.text = product.name;
//       _descriptionController.text = product.description;
//       _priceController.text = product.price.toString();
//       _costController.text = product.cost.toString();
//       _stockController.text = product.stock.toString();
//       _skuController.text = product.sku;
//       _notesController.text = product.internalNotes ?? '';
//       _selectedCategory = product.categoryId;
//       _isActive = product.isActive;
//       _images = List.from(product.images);
//       if (_images.isNotEmpty) {
//         _imageUrlController.text = _images.first;
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _descriptionController.dispose();
//     _priceController.dispose();
//     _costController.dispose();
//     _stockController.dispose();
//     _skuController.dispose();
//     _notesController.dispose();
//     _imageUrlController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Get.theme;
//     final isEdit = widget.product != null;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
//         centerTitle: true,
//         actions: [
//           if (isEdit) IconButton(
//             icon: const Icon(Icons.delete),
//             onPressed: _deleteProduct,
//             color: Colors.red,
//             tooltip: 'Delete',
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: AppSizes.paddingAll(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header
//               Text(
//                 isEdit ? 'Edit Product' : 'Add New Product',
//                 style: theme.textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: theme.primaryColorDark,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'Manage your product details and inventory',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: theme.hintColor,
//                 ),
//               ),
//               const SizedBox(height: 24),
//
//               // Product Image Section
//               _buildImageSection(theme),
//
//               const SizedBox(height: 24),
//
//               // Basic Information
//               _buildSectionTitle('Basic Information', theme),
//               _buildTextField(
//                 controller: _nameController,
//                 label: 'Product Name',
//                 hint: 'e.g., Hair Shampoo',
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter product name';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildCategoryDropdown(theme),
//               const SizedBox(height: 16),
//               _buildTextField(
//                 controller: _descriptionController,
//                 label: 'Description',
//                 hint: 'Describe the product...',
//                 maxLines: 3,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter product description';
//                   }
//                   return null;
//                 },
//               ),
//
//               const SizedBox(height: 24),
//
//               // Pricing & Inventory
//               _buildSectionTitle('Pricing & Inventory', theme),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildTextField(
//                       controller: _priceController,
//                       label: 'Price (\$)',
//                       hint: '0.00',
//                       keyboardType: TextInputType.number,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter price';
//                         }
//                         if (double.tryParse(value) == null) {
//                           return 'Please enter a valid number';
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: _buildTextField(
//                       controller: _costController,
//                       label: 'Cost (\$)',
//                       hint: '0.00',
//                       keyboardType: TextInputType.number,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter cost';
//                         }
//                         if (double.tryParse(value) == null) {
//                           return 'Please enter a valid number';
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildTextField(
//                       controller: _stockController,
//                       label: 'Stock Quantity',
//                       hint: '0',
//                       keyboardType: TextInputType.number,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter stock quantity';
//                         }
//                         if (int.tryParse(value) == null) {
//                           return 'Please enter a valid number';
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: _buildTextField(
//                       controller: _skuController,
//                       label: 'SKU',
//                       hint: 'Product SKU',
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter SKU';
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 24),
//
//               // Product Settings
//               _buildSectionTitle('Product Settings', theme),
//               Row(
//                 children: [
//                   Switch(
//                     value: _isActive,
//                     onChanged: (value) {
//                       setState(() {
//                         _isActive = value;
//                       });
//                     },
//                     activeColor: theme.primaryColor,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Active',
//                     style: theme.textTheme.bodyMedium?.copyWith(
//                       color: theme.primaryColorDark,
//                     ),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 16),
//
//               _buildTextField(
//                 controller: _notesController,
//                 label: 'Internal Notes (Optional)',
//                 hint: 'Internal notes about this product...',
//                 maxLines: 3,
//               ),
//
//               const SizedBox(height: 32),
//
//               // Action Buttons
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => Get.back(),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         side: BorderSide(color: theme.dividerColor),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         'Cancel',
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           color: theme.hintColor,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: _saveProduct,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: theme.primaryColor,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         isEdit ? 'Update Product' : 'Add Product',
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 32),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildImageSection(ThemeData theme) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Product Image',
//           style: theme.textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.w600,
//             color: theme.primaryColorDark,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Upload an image or provide an image URL for the product',
//           style: theme.textTheme.bodySmall?.copyWith(
//             color: theme.hintColor,
//           ),
//         ),
//         const SizedBox(height: 16),
//
//         // Image Preview
//         if (_images.isNotEmpty) ...[
//           Container(
//             width: double.infinity,
//             height: 200,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//               image: DecorationImage(
//                 image: NetworkImage(_images.first),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//         ],
//
//         // URL Input
//         _buildTextField(
//           controller: _imageUrlController,
//           label: 'Image URL',
//           hint: 'https://example.com/product-image.jpg',
//           prefixIcon: Icons.link,
//           onChanged: (value) {
//             if (value.isNotEmpty) {
//               setState(() {
//                 _images = [value];
//               });
//             }
//           },
//         ),
//
//         const SizedBox(height: 12),
//
//         // Upload Button
//         OutlinedButton(
//           onPressed: () {
//             // TODO: Implement image upload
//             Get.snackbar(
//               'Info',
//               'Image upload feature coming soon',
//               snackPosition: SnackPosition.BOTTOM,
//             );
//           },
//           style: OutlinedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             side: BorderSide(color: theme.primaryColor),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.upload),
//               const SizedBox(width: 8),
//               Text(
//                 'Upload File',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: theme.primaryColor,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSectionTitle(String title, ThemeData theme) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Text(
//         title,
//         style: theme.textTheme.titleMedium?.copyWith(
//           fontWeight: FontWeight.bold,
//           color: theme.primaryColorDark,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     IconData? prefixIcon,
//     TextInputType? keyboardType,
//     int? maxLines = 1,
//     String? Function(String?)? validator,
//     void Function(String)? onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: Get.theme.textTheme.bodyMedium?.copyWith(
//             fontWeight: FontWeight.w600,
//             color: Get.theme.primaryColorDark,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           decoration: InputDecoration(
//             hintText: hint,
//             prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Get.theme.dividerColor),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Get.theme.dividerColor),
//             ),
//           ),
//           keyboardType: keyboardType,
//           maxLines: maxLines,
//           validator: validator,
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }
//
//   Widget _buildCategoryDropdown(ThemeData theme) {
//     final productCategories = controller.productCategories;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Select Category',
//           style: theme.textTheme.bodyMedium?.copyWith(
//             fontWeight: FontWeight.w600,
//             color: theme.primaryColorDark,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             border: Border.all(color: theme.dividerColor),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<String>(
//               value: _selectedCategory,
//               items: [
//                 const DropdownMenuItem<String>(
//                   value: null,
//                   child: Text('Select Category'),
//                 ),
//                 ...productCategories.map((category) {
//                   return DropdownMenuItem<String>(
//                     value: category.id,
//                     child: Text(category.name),
//                   );
//                 }).toList(),
//               ],
//               onChanged: (value) {
//                 setState(() {
//                   _selectedCategory = value;
//                 });
//               },
//               isExpanded: true,
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               icon: const Icon(Icons.arrow_drop_down),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   void _saveProduct() {
//     if (_formKey.currentState!.validate()) {
//       if (_selectedCategory == null) {
//         Get.snackbar(
//           'Error',
//           'Please select a category',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//         return;
//       }
//
//       final product = Product(
//         id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
//         name: _nameController.text,
//         description: _descriptionController.text,
//         categoryId: _selectedCategory!,
//         price: double.parse(_priceController.text),
//         cost: double.parse(_costController.text),
//         stock: int.parse(_stockController.text),
//         sku: _skuController.text,
//         images: _images,
//         isActive: _isActive,
//         internalNotes: _notesController.text.isNotEmpty ? _notesController.text : null,
//         createdAt: widget.product?.createdAt ?? DateTime.now(),
//         updatedAt: DateTime.now(),
//       );
//
//       if (widget.product != null) {
//         controller.updateProduct(widget.product!.id, product);
//       } else {
//         controller.addProduct(product);
//       }
//     }
//   }
//
//   void _deleteProduct() {
//     Get.defaultDialog(
//       title: 'Delete Product',
//       middleText: 'Are you sure you want to delete this product? This action cannot be undone.',
//       textConfirm: 'Delete',
//       textCancel: 'Cancel',
//       confirmTextColor: Colors.white,
//       buttonColor: Colors.red,
//       onConfirm: () {
//         controller.deleteProduct(widget.product!.id);
//         Get.back(); // Close dialog
//         Get.back(); // Close screen
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
// }