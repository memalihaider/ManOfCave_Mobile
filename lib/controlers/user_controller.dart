// controllers/user_controller.dart
import 'package:get/get.dart';

class UserController extends GetxController {
  final user = User(
    id: '1',
    name: 'John Doe',
    email: 'john.doe@example.com',
    phoneNumber: '+1 234 567 8900',
    profileImage: null,
  ).obs;

  void updateUser(User newUser) {
    user.value = newUser;
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profileImage;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profileImage,
  });
}