// // controllers/home_controller.dart
// import 'package:get/get.dart';
//
// class HomeController extends GetxController {
//   // We'll keep this controller for coordinating between other controllers
//   // or for any home-specific logic
//
//   final RxBool _isLoading = false.obs;
//
//   bool get isLoading => _isLoading.value;
//
//   @override
//   void onInit() {
//     super.onInit();
//     _initializeControllers();
//   }
//
//   void _initializeControllers() {
//     // All controllers are automatically initialized via Get.put() in main.dart
//     // This method is for any coordination needed
//   }
// }