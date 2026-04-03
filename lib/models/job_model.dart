import 'package:cloud_firestore/cloud_firestore.dart';

enum JobStatus { open, inProgress, completed, cancelled }

class JobModel {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final String title;
  final String description;
  final String category;
  final double budget;
  final DateTime deadline;
  final JobStatus status;
  final List<String> requiredSkills;
  final DateTime createdAt;
  final int bidCount;
  final String? assignedFreelancerId;
  final List<String> attachments;

  JobModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    required this.deadline,
    required this.status,
    this.requiredSkills = const [],
    required this.createdAt,
    this.bidCount = 0,
    this.assignedFreelancerId,
    this.attachments = const [],
  });

  factory JobModel.fromMap(Map<String, dynamic> map, String id) {
    return JobModel(
      id: id,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientPhotoUrl: map['clientPhotoUrl'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      budget: (map['budget'] ?? 0).toDouble(),
      deadline: map['deadline'] is Timestamp
          ? (map['deadline'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 7)),
      status: JobStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => JobStatus.open,
      ),
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      bidCount: map['bidCount'] ?? 0,
      assignedFreelancerId: map['assignedFreelancerId'],
      attachments: List<String>.from(map['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientPhotoUrl': clientPhotoUrl,
      'title': title,
      'description': description,
      'category': category,
      'budget': budget,
      'deadline': Timestamp.fromDate(deadline),
      'status': status.name,
      'requiredSkills': requiredSkills,
      'createdAt': Timestamp.fromDate(createdAt),
      'bidCount': bidCount,
      'assignedFreelancerId': assignedFreelancerId,
      'attachments': attachments,
    };
  }
}
