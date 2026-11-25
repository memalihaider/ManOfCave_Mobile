import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyTiming {
  final String opening;
  final String closing;
  final bool closed;

  WeeklyTiming({
    required this.opening,
    required this.closing,
    required this.closed,
  });

  factory WeeklyTiming.fromFirestore(Map<String, dynamic> data) {
    return WeeklyTiming(
      opening: data['opening']?.toString() ?? '09:00',
      closing: data['closing']?.toString() ?? '18:00',
      closed: data['closed'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'opening': opening,
      'closing': closing,
      'closed': closed,
    };
  }

  bool isOpenAt(DateTime dateTime) {
    if (closed) return false;

    final currentTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return currentTime.compareTo(opening) >= 0 && currentTime.compareTo(closing) <= 0;
  }

  String get businessHours => closed ? 'Closed' : '$opening - $closing';
}

class Branch {
  final String id;
  final String name;
  final String address;
  final String city;
  final String country;
  final String phone;
  final String email;
  final String openingTime;
  final String closingTime;
  final String status;
  final String? description;
  final String? image;
  final String? managerName;
  final String? managerEmail;
  final String? managerPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  // New field for weekly timings
  final Map<String, WeeklyTiming> weeklyTimings;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.country,
    required this.phone,
    required this.email,
    required this.openingTime,
    required this.closingTime,
    required this.status,
    this.description,
    this.image,
    this.managerName,
    this.managerEmail,
    this.managerPhone,
    required this.createdAt,
    required this.updatedAt,
    this.weeklyTimings = const {},
  });

  // Factory method to create Branch from Firestore Document
  factory Branch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Helper function to safely parse timestamps
    DateTime _parseTimestamp(dynamic timestamp) {
      if (timestamp == null) {
        return DateTime.now();
      }
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      if (timestamp is DateTime) {
        return timestamp;
      }
      if (timestamp is String) {
        return DateTime.tryParse(timestamp) ?? DateTime.now();
      }
      return DateTime.now();
    }

    // Parse weekly timings
    Map<String, WeeklyTiming> parsedWeeklyTimings = {};
    if (data['weeklyTimings'] != null) {
      final timingsData = data['weeklyTimings'] as Map<String, dynamic>;
      timingsData.forEach((day, timingData) {
        if (timingData is Map<String, dynamic>) {
          parsedWeeklyTimings[day] = WeeklyTiming.fromFirestore(timingData);
        }
      });
    }

    return Branch(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      country: data['country']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      openingTime: data['openingTime']?.toString() ?? '09:00',
      closingTime: data['closingTime']?.toString() ?? '18:00',
      status: data['status']?.toString() ?? 'active',
      description: data['description']?.toString(),
      image: data['image']?.toString(),
      managerName: data['managerName']?.toString(),
      managerEmail: data['managerEmail']?.toString(),
      managerPhone: data['managerPhone']?.toString(),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      weeklyTimings: parsedWeeklyTimings,
    );
  }

  // Convert Branch to Map for Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> weeklyTimingsData = {};
    weeklyTimings.forEach((day, timing) {
      weeklyTimingsData[day] = timing.toFirestore();
    });

    return {
      'name': name,
      'address': address,
      'city': city,
      'country': country,
      'phone': phone,
      'email': email,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'status': status,
      if (description != null) 'description': description,
      if (image != null) 'image': image,
      if (managerName != null) 'managerName': managerName,
      if (managerEmail != null) 'managerEmail': managerEmail,
      if (managerPhone != null) 'managerPhone': managerPhone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'weeklyTimings': weeklyTimingsData,
    };
  }

  // Helper methods
  bool get isActive => status == 'active';

  bool isOpenNow() {
    if (!isActive) return false;

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);

    final todayTiming = weeklyTimings[dayName];
    if (todayTiming == null) {
      // Fallback to old method if weeklyTimings not available
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      return currentTime.compareTo(openingTime) >= 0 && currentTime.compareTo(closingTime) <= 0;
    }

    return todayTiming.isOpenAt(now);
  }

  bool isOpenOn(DateTime dateTime) {
    if (!isActive) return false;

    final dayName = _getDayName(dateTime.weekday);
    final dayTiming = weeklyTimings[dayName];

    if (dayTiming == null) return false;
    return dayTiming.isOpenAt(dateTime);
  }

  String getBusinessHoursForDay(String day) {
    final timing = weeklyTimings[day.toLowerCase()];
    if (timing != null) {
      return timing.businessHours;
    }
    // Fallback
    return '$openingTime - $closingTime';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  String get fullAddress => '$address, $city, $country';

  String get businessHours => '$openingTime - $closingTime';

  // Get formatted weekly schedule
  Map<String, String> get weeklySchedule {
    final schedule = <String, String>{};
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    for (final day in days) {
      final timing = weeklyTimings[day];
      if (timing != null) {
        schedule[day] = timing.businessHours;
      } else {
        schedule[day] = '$openingTime - $closingTime';
      }
    }
    return schedule;
  }

  // Copy with method for updates
  Branch copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? country,
    String? phone,
    String? email,
    String? openingTime,
    String? closingTime,
    String? status,
    String? description,
    String? image,
    String? managerName,
    String? managerEmail,
    String? managerPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, WeeklyTiming>? weeklyTimings,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      status: status ?? this.status,
      description: description ?? this.description,
      image: image ?? this.image,
      managerName: managerName ?? this.managerName,
      managerEmail: managerEmail ?? this.managerEmail,
      managerPhone: managerPhone ?? this.managerPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      weeklyTimings: weeklyTimings ?? this.weeklyTimings,
    );
  }
}