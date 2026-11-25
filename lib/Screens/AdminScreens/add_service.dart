// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:jam_beauty_lounge/Screens/AdminScreens/product_service_model.dart';
// import 'package:jam_beauty_lounge/Screens/AdminScreens/product_servicecontroller.dart';
// import '../../constants/app_sizes.dart';
//
// class AddServiceScreen extends StatefulWidget {
//   final Service? service;
//
//   const AddServiceScreen({super.key, this.service});
//
//   @override
//   _AddServiceScreenState createState() => _AddServiceScreenState();
// }
//
// class _AddServiceScreenState extends State<AddServiceScreen> {
//   final ProductServiceController controller = Get.find();
//   final _formKey = GlobalKey<FormState>();
//
//   // Form controllers
//   final _nameController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _durationController = TextEditingController();
//   final _notesController = TextEditingController();
//   final _imageUrlController = TextEditingController();
//
//   String? _selectedCategory;
//   String? _selectedRoom;
//   bool _isActive = true;
//   bool _requiresRoom = false;
//   List<String> _images = [];
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Pre-fill form if editing
//     if (widget.service != null) {
//       final service = widget.service!;
//       _nameController.text = service.name;
//       _descriptionController.text = service.description;
//       _priceController.text = service.price.toString();
//       _durationController.text = service.duration.toString();
//       _notesController.text = service.internalNotes ?? '';
//       _selectedCategory = service.categoryId;
//       _selectedRoom = service.roomId;
//       _isActive = service.isActive;
//       _requiresRoom = service.requiresRoom;
//       _images = List.from(service.images);
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
//     _durationController.dispose();
//     _notesController.dispose();
//     _imageUrlController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Get.theme;
//     final isEdit = widget.service != null;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(isEdit ? 'Edit Service' : 'Add New Service'),
//         centerTitle: true,
//         actions: [
//           if (isEdit) IconButton(
//             icon: const Icon(Icons.delete),
//             onPressed: _deleteService,
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
//                 isEdit ? 'Edit Service' : 'Add New Service',
//                 style: theme.textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: theme.primaryColorDark,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 isEdit ? 'Update service details' : 'Create a new service offering for your business',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: theme.hintColor,
//                 ),
//               ),
//               const SizedBox(height: 24),
//
//               // Service Image Section
//               _buildImageSection(theme),
//
//               const SizedBox(height: 24),
//
//               // Basic Information
//               _buildSectionTitle('Basic Information', theme),
//               _buildTextField(
//                 controller: _nameController,
//                 label: 'Service Name',
//                 hint: 'e.g., Classic Haircut',
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter service name';
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
//                 hint: 'Describe the service...',
//                 maxLines: 3,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter service description';
//                   }
//                   return null;
//                 },
//               ),
//
//               const SizedBox(height: 24),
//
//               // Service Settings
//               _buildSectionTitle('Service Settings', theme),
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
//                       controller: _durationController,
//                       label: 'Duration (minutes)',
//                       hint: '30',
//                       keyboardType: TextInputType.number,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter duration';
//                         }
//                         if (int.tryParse(value) == null) {
//                           return 'Please enter a valid number';
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 16),
//
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
//                   const Spacer(),
//                   Switch(
//                     value: _requiresRoom,
//                     onChanged: (value) {
//                       setState(() {
//                         _requiresRoom = value;
//                       });
//                     },
//                     activeColor: theme.primaryColor,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Requires Room',
//                     style: theme.textTheme.bodyMedium?.copyWith(
//                       color: theme.primaryColorDark,
//                     ),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 16),
//
//               if (_requiresRoom) _buildRoomDropdown(theme),
//
//               const SizedBox(height: 16),
//
//               _buildTextField(
//                 controller: _notesController,
//                 label: 'Internal Notes (Optional)',
//                 hint: 'Internal notes about this service...',
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
//                       onPressed: _saveService,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: theme.primaryColor,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         isEdit ? 'Update Service' : 'Add Service',
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
//           'Service Image',
//           style: theme.textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.w600,
//             color: theme.primaryColorDark,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Upload an image or provide an image URL for the service',
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
//             child: _images.first.contains('example.com')
//                 ? Center(
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.5),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'Service preview',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             )
//                 : null,
//           ),
//           const SizedBox(height: 16),
//         ],
//
//         // URL Input
//         _buildTextField(
//           controller: _imageUrlController,
//           label: 'Image URL',
//           hint: 'https://example.com/service-image.jpg',
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
//         padding: const EdgeInsets.only(bottom: 12),
//         child: Text(
//           title,
//           style: theme.textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: theme.primaryColorDark,
//           ),
//         ),
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
//     final serviceCategories = controller.serviceCategories;
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
//                   child: Text('Select category'),
//                 ),
//                 ...serviceCategories.map((category) {
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
//   Widget _buildRoomDropdown(ThemeData theme) {
//     final availableRooms = controller.rooms.where((room) => room.isActive).toList();
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Select Room',
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
//               value: _selectedRoom,
//               items: [
//                 const DropdownMenuItem<String>(
//                   value: null,
//                   child: Text('Select room'),
//                 ),
//                 ...availableRooms.map((room) {
//                   return DropdownMenuItem<String>(
//                     value: room.id,
//                     child: Text(room.name),
//                   );
//                 }).toList(),
//               ],
//               onChanged: (value) {
//                 setState(() {
//                   _selectedRoom = value;
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
//   void _saveService() {
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
//       if (_requiresRoom && _selectedRoom == null) {
//         Get.snackbar(
//           'Error',
//           'Please select a room',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//         return;
//       }
//
//       final service = Service(
//         id: widget.service?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
//         name: _nameController.text,
//         description: _descriptionController.text,
//         categoryId: _selectedCategory!,
//         price: double.parse(_priceController.text),
//         duration: int.parse(_durationController.text),
//         images: _images,
//         isActive: _isActive,
//         roomId: _requiresRoom ? _selectedRoom : null,
//         requiresRoom: _requiresRoom,
//         internalNotes: _notesController.text.isNotEmpty ? _notesController.text : null,
//         createdAt: widget.service?.createdAt ?? DateTime.now(),
//         updatedAt: DateTime.now(),
//       );
//
//       if (widget.service != null) {
//         controller.updateService(widget.service!.id, service);
//       } else {
//         controller.addService(service);
//       }
//     }
//   }
//
//   void _deleteService() {
//     Get.defaultDialog(
//       title: 'Delete Service',
//       middleText: 'Are you sure you want to delete this service? This action cannot be undone.',
//       textConfirm: 'Delete',
//       textCancel: 'Cancel',
//       confirmTextColor: Colors.white,
//       buttonColor: Colors.red,
//       onConfirm: () {
//         controller.deleteService(widget.service!.id);
//         Get.back(); // Close dialog
//         Get.back(); // Close screen
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