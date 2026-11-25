// models/city_model.dart
class City {
  final String name;
  final int branchCount;
  final String image;

  City({
    required this.name,
    required this.branchCount,
    required this.image,
  });

  // Factory method to create City from Map
  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      name: map['name'] as String,
      branchCount: map['branchCount'] as int,
      image: map['image'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'branchCount': branchCount,
      'image': image,
    };
  }
}