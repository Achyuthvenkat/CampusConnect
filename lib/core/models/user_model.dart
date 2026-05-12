import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String college;
  final String department;
  final int year;
  final String bio;
  final String? avatarUrl;
  final List<String> skills;
  final double hourlyRate;
  final bool availability;
  final List<String> portfolioUrls;
  final double rating;
  final int reviewCount;
  final List<String> bookmarks;
  final String userType; // 'freelancer', 'client', 'both'
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.college = 'Saveetha University',
    this.department = '',
    this.year = 1,
    this.bio = '',
    this.avatarUrl,
    this.skills = const [],
    this.hourlyRate = 0,
    this.availability = true,
    this.portfolioUrls = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.bookmarks = const [],
    this.userType = 'freelancer',
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      college: data['college'] ?? 'Saveetha University',
      department: data['department'] ?? '',
      year: data['year'] ?? 1,
      bio: data['bio'] ?? '',
      avatarUrl: data['avatarUrl'],
      skills: List<String>.from(data['skills'] ?? []),
      hourlyRate: (data['hourlyRate'] ?? 0).toDouble(),
      availability: data['availability'] ?? true,
      portfolioUrls: List<String>.from(data['portfolioUrls'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      bookmarks: List<String>.from(data['bookmarks'] ?? []),
      userType: data['userType'] ?? 'freelancer',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'college': college,
      'department': department,
      'year': year,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'skills': skills,
      'hourlyRate': hourlyRate,
      'availability': availability,
      'portfolioUrls': portfolioUrls,
      'rating': rating,
      'reviewCount': reviewCount,
      'bookmarks': bookmarks,
      'userType': userType,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? department,
    int? year,
    String? bio,
    String? avatarUrl,
    List<String>? skills,
    double? hourlyRate,
    bool? availability,
    List<String>? portfolioUrls,
    double? rating,
    int? reviewCount,
    List<String>? bookmarks,
    String? userType,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      college: college,
      department: department ?? this.department,
      year: year ?? this.year,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      skills: skills ?? this.skills,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      availability: availability ?? this.availability,
      portfolioUrls: portfolioUrls ?? this.portfolioUrls,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      bookmarks: bookmarks ?? this.bookmarks,
      userType: userType ?? this.userType,
      createdAt: createdAt,
    );
  }

  String get firstName => name.split(' ').first;
  bool get hasPortfolio => portfolioUrls.isNotEmpty;
  bool get isProfileComplete => bio.isNotEmpty && skills.isNotEmpty;

  @override
  List<Object?> get props => [uid, name, email, skills, rating, availability];
}
