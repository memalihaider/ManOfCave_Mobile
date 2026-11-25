import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WeeklyTiming {
  final String opening;
  final String closing;

  WeeklyTiming({
    required this.opening,
    required this.closing,
  });

  factory WeeklyTiming.fromFirestore(Map<String, dynamic> data) {
    return WeeklyTiming(
      opening: data['start']?.toString() ?? '09:00',
      closing: data['end']?.toString() ?? '18:00',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'start': opening,
      'end': closing,
    };
  }
}

class LunchBreak{
  final String duration;
  final String end;
  final String start;

  LunchBreak({
    required this.duration,
    required this.end,
    required this.start,
});
  factory LunchBreak.fromFirestore(Map<String,dynamic> data){
    return LunchBreak(
    duration: data['duration']?.toString() ?? '0',
    end: data['end']?.toString() ?? '0',
  start: data['start']?.toString() ?? '0'
  );
  }

  Map<String,dynamic> toFirestore(){
    return{
      'start':start,
      'end':end
    };
  }
}

class Staff {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String branch;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Personal details
  final String address;
  final String? avatar;
  final String? bloodGroup;
  final String dateOfBirth;
  final String? description;
  final String documentId; // NEW FIELD
  final String? emergencyContact;
  final String experience;
  final String gender;
  final String hireDate;
  final String maritalStatus;
  final String nationality;
  final String? visaExpiry;

  // Professional details
  final double rating;
  final int reviews;
  final double salary;
  final List<String> specialization;

  final Map<String, WeeklyTiming> weeklyTimings;
  final LunchBreak? lunchBreak;


  Staff({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.branch,
    required this.status,
    required this.createdAt,
    required this.updatedAt,

    // Personal details
    required this.address,
    this.avatar,
    this.bloodGroup,
    required this.dateOfBirth,
    this.description,
    required this.documentId, // NEW FIELD
    this.emergencyContact,
    required this.experience,
    required this.gender,
    required this.hireDate,
    required this.maritalStatus,
    required this.nationality,
    this.visaExpiry,

    // Professional details
    required this.rating,
    required this.reviews,
    required this.salary,
    required this.specialization,

    this.weeklyTimings=const {},
    this.lunchBreak,
  });

  // Factory method to create Staff from Firestore Document
  factory Staff.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Map<String,WeeklyTiming> parseWeeklyTimings={};
    if(data['weeklyTimings']!=null){
     final timingsData=data['weeklyTimings'] as Map<String,dynamic>;
     timingsData.forEach((day,timingData){
       if(timingData is Map<String,dynamic>){
         parseWeeklyTimings[day]=WeeklyTiming.fromFirestore(timingData);
       }
     });
    }

    LunchBreak? parseLunchBreak;
    if(data['lunchBreak']!=null){
      final lunchBreakData=data['lunchBreak'] as Map<String,dynamic>;
      parseLunchBreak=LunchBreak.fromFirestore(lunchBreakData);
    }

    return Staff(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? '',
      branch: data['branch'] ?? '',
      status: data['status'] ?? 'inactive',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),

      // Personal details
      address: data['address'] ?? '',
      avatar: data['avatar'],
      bloodGroup: data['bloodGroup'],
      dateOfBirth: data['dateOfBirth'] ?? '',
      description: data['description'],
      documentId: data['documentId'] ?? doc.id, // Use doc.id as fallback
      emergencyContact: data['emergencyContact'],
      experience: data['experience'] ?? '0',
      gender: data['gender'] ?? '',
      hireDate: data['hireDate'] ?? '',
      maritalStatus: data['maritalStatus'] ?? '',
      nationality: data['nationality'] ?? '',
      visaExpiry: data['visaExpiry'],

      // Professional details
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (data['reviews'] as num?)?.toInt() ?? 0,
      salary: (data['salary'] as num?)?.toDouble() ?? 0.0,
      specialization: List<String>.from(data['specialization'] ?? []),
      weeklyTimings: parseWeeklyTimings,
      lunchBreak: parseLunchBreak,
    );
  }

  // Convert Staff to Map for Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> weeklyTimingsData = {};
    weeklyTimings.forEach((day, timing) {
      weeklyTimingsData[day] = timing.toFirestore();
    });
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'branch': branch,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),

      // Personal details
      'address': address,
      if (avatar != null && avatar!.isNotEmpty) 'avatar': avatar,
      if (bloodGroup != null && bloodGroup!.isNotEmpty) 'bloodGroup': bloodGroup,
      'dateOfBirth': dateOfBirth,
      if (description != null && description!.isNotEmpty) 'description': description,
      'documentId': documentId,
      if (emergencyContact != null && emergencyContact!.isNotEmpty) 'emergencyContact': emergencyContact,
      'experience': experience,
      'gender': gender,
      'hireDate': hireDate,
      'maritalStatus': maritalStatus,
      'nationality': nationality,
      if (visaExpiry != null && visaExpiry!.isNotEmpty) 'visaExpiry': visaExpiry,

      // Professional details
      'rating': rating,
      'reviews': reviews,
      'salary': salary,
      'specialization': specialization,
      'weeklyTimings': weeklyTimingsData,
      if (lunchBreak != null) 'lunchBreak': lunchBreak!.toFirestore(),
    };
  }

  String get formattedLunchBreak {
    if (lunchBreak == null) return 'No lunch break set';
    print('${lunchBreak!.start} - ${lunchBreak!.end} (${lunchBreak!.duration})');
    return '${lunchBreak!.start} - ${lunchBreak!.end} (${lunchBreak!.duration})';
  }
  // Get formatted weekly schedule
  Map<String, String> get weeklySchedule {
    final schedule = <String, String>{};
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    for (final day in days) {
      final openingTime = weeklyTimings[day]?.opening ?? '09:00';
      final closingTime = weeklyTimings[day]?.closing ?? '18:00';
      final timing = weeklyTimings[day];
      if (timing != null) {
        schedule[day] = '$openingTime - $closingTime';
      }
    }
    return schedule;
  }

  // Copy with method for updates
  Staff copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? branch,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,

    // Personal details
    String? address,
    String? avatar,
    String? bloodGroup,
    String? dateOfBirth,
    String? description,
    String? documentId,
    String? emergencyContact,
    String? experience,
    String? gender,
    String? hireDate,
    String? maritalStatus,
    String? nationality,
    String? visaExpiry,

    // Professional details
    double? rating,
    int? reviews,
    double? salary,
    List<String>? specialization,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      branch: branch ?? this.branch,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,

      // Personal details
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      description: description ?? this.description,
      documentId: documentId ?? this.documentId,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      experience: experience ?? this.experience,
      gender: gender ?? this.gender,
      hireDate: hireDate ?? this.hireDate,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      nationality: nationality ?? this.nationality,
      visaExpiry: visaExpiry ?? this.visaExpiry,

      // Professional details
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      salary: salary ?? this.salary,
      specialization: specialization ?? this.specialization,
    );
  }

  // Check if staff is active
  bool get isActive => status == 'active';

  // Parse experience string to integer
  int get experienceYears => int.tryParse(experience) ?? 0;

  // Format rating to 1 decimal place
  String get formattedRating => rating.toStringAsFixed(1);

  // Format reviews count
  String get formattedReviews => '($reviews reviews)';

  // Join specialization list
  String get specialtiesText => specialization.join(', ');

  // Check if visa expiry exists
  bool get hasVisaExpiry => visaExpiry != null && visaExpiry!.isNotEmpty;

  // Get age from date of birth
  int get age {
    try {
      final birthDate = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  // Get formatted hire date
  String get formattedHireDate {
    try {
      final hireDateTime = DateTime.parse(hireDate);
      return '${hireDateTime.day}/${hireDateTime.month}/${hireDateTime.year}';
    } catch (e) {
      return hireDate;
    }
  }

  // Check if visa is expired
  bool get isVisaExpired {
    if (visaExpiry == null || visaExpiry!.isEmpty) return false;
    try {
      final expiryDate = DateTime.parse(visaExpiry!);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return false;
    }
  }

  // Get days until visa expiry
  int? get daysUntilVisaExpiry {
    if (visaExpiry == null || visaExpiry!.isEmpty) return null;
    try {
      final expiryDate = DateTime.parse(visaExpiry!);
      final difference = expiryDate.difference(DateTime.now());
      return difference.inDays;
    } catch (e) {
      return null;
    }
  }

  // Get display name with role
  String get displayNameWithRole => '$name ($role)';

  // Get staff type based on role
  String get staffType {
    switch (role.toLowerCase()) {
      case 'makeup':
        return 'Makeup Artist';
      case 'barber':
        return 'Barber';
      case 'hairstylist':
        return 'Hair Stylist';
      case 'massage':
        return 'Massage Therapist';
      case 'skincare':
        return 'Skincare Specialist';
      default:
        return role;
    }
  }

  // Get formatted salary
  String get formattedSalary => salary.toStringAsFixed(0);

  // Get formatted phone number
  String get formattedPhone {
    if (phone.isEmpty) return 'N/A';
    // Add formatting logic for phone numbers
    return phone;
  }

  // Get formatted address
  String get formattedAddress {
    final parts = [address];
    return parts.where((part) => part.isNotEmpty).join(', ');
  }

  // Get display document ID (shortened)
  String get displayDocumentId {
    if (documentId.length > 12) {
      return '${documentId.substring(0, 8)}...';
    }
    return documentId;
  }

  // Get visa expiry status
  String get visaStatus {
    if (!hasVisaExpiry) return 'No Visa';
    if (isVisaExpired) return 'Expired';

    final daysLeft = daysUntilVisaExpiry;
    if (daysLeft != null) {
      if (daysLeft < 30) return 'Expiring Soon';
      if (daysLeft < 90) return 'Valid (${daysLeft}d left)';
      return 'Valid';
    }
    return 'Valid';
  }

  // Get visa expiry color
  Color get visaStatusColor {
    if (!hasVisaExpiry) return Colors.grey;
    if (isVisaExpired) return Colors.red;

    final daysLeft = daysUntilVisaExpiry;
    if (daysLeft != null && daysLeft < 30) return Colors.orange;
    return Colors.green;
  }

  // Get status color
  Color get statusColor {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'on-leave':
        return Colors.orange;
      case 'terminated':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Get formatted experience
  String get formattedExperience {
    final years = experienceYears;
    if (years == 0) return 'Fresher';
    if (years == 1) return '1 year';
    return '$years years';
  }

  // Check if staff has avatar
  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;

  // Get initials for avatar placeholder
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }

  // Get blood group display
  String get bloodGroupDisplay {
    if (bloodGroup == null || bloodGroup!.isEmpty) return 'N/A';
    return bloodGroup!;
  }

  // Check if staff is make-up artist
  bool get isMakeupArtist => role.toLowerCase() == 'makeup';

  // Check if staff is barber
  bool get isBarber => role.toLowerCase() == 'barber';

  // Check if staff is hair stylist
  bool get isHairStylist => role.toLowerCase() == 'hairstylist';

  // Check if staff is available for booking
  bool isAvailableForBooking({
    required DateTime date,
    required String timeSlot,
  }) {
    return isActive;
  }

  // For backward compatibility with older code
  Map<String, dynamic> toLegacyMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'branch': branch,
      'status': status,
      'rating': rating,
      'reviews': reviews,
      'specialization': specialization,
      'avatar': avatar,
      'experience': experienceYears,
      'isAvailable': isActive,
    };
  }

  // Get summary for quick display
  Map<String, dynamic> get summary {
    return {
      'id': id,
      'name': name,
      'role': role,
      'branch': branch,
      'status': status,
      'rating': rating,
      'experience': formattedExperience,
      'specialization': specialtiesText,
      'avatar': avatar,
      'phone': phone,
      'email': email,
    };
  }
}