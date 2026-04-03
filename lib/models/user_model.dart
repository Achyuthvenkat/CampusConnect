import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? bio;
  final String college;
  final List<String> skills;
  final String? availability;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final List<String> portfolioUrls;
  final bool isAvailable;
  final DateTime createdAt;
  final String? fcmToken;
  final List<String> bookmarks;
  final int completedJobs;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.bio,
    required this.college,
    this.skills = const [],
    this.availability,
    this.hourlyRate = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.portfolioUrls = const [],
    this.isAvailable = true,
    required this.createdAt,
    this.fcmToken,
    this.bookmarks = const [],
    this.completedJobs = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      bio: map['bio'],
      college: map['college'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      availability: map['availability'],
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      portfolioUrls: List<String>.from(map['portfolioUrls'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      fcmToken: map['fcmToken'],
      bookmarks: List<String>.from(map['bookmarks'] ?? []),
      completedJobs: map['completedJobs'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'college': college,
      'skills': skills,
      'availability': availability,
      'hourlyRate': hourlyRate,
      'rating': rating,
      'reviewCount': reviewCount,
      'portfolioUrls': portfolioUrls,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'fcmToken': fcmToken,
      'bookmarks': bookmarks,
      'completedJobs': completedJobs,
    };
  }

  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? bio,
    String? college,
    List<String>? skills,
    String? availability,
    double? hourlyRate,
    double? rating,
    int? reviewCount,
    List<String>? portfolioUrls,
    bool? isAvailable,
    String? fcmToken,
    List<String>? bookmarks,
    int? completedJobs,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      college: college ?? this.college,
      skills: skills ?? this.skills,
      availability: availability ?? this.availability,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      portfolioUrls: portfolioUrls ?? this.portfolioUrls,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      bookmarks: bookmarks ?? this.bookmarks,
      completedJobs: completedJobs ?? this.completedJobs,
    );
  }
}
