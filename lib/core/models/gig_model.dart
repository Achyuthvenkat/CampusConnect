import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GigModel extends Equatable {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientAvatarUrl;
  final String title;
  final String description;
  final String category;
  final double budget;
  final DateTime deadline;
  final String status;
  final List<String> attachmentUrls;
  final List<String> tags;
  final int bidCount;
  final String? selectedBidId;
  final DateTime createdAt;

  const GigModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientAvatarUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    required this.deadline,
    this.status = 'open',
    this.attachmentUrls = const [],
    this.tags = const [],
    this.bidCount = 0,
    this.selectedBidId,
    required this.createdAt,
  });

  factory GigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GigModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientAvatarUrl: data['clientAvatarUrl'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      budget: (data['budget'] ?? 0).toDouble(),
      deadline:
          (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      status: data['status'] ?? 'open',
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      bidCount: data['bidCount'] ?? 0,
      selectedBidId: data['selectedBidId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientAvatarUrl': clientAvatarUrl,
      'title': title,
      'description': description,
      'category': category,
      'budget': budget,
      'deadline': Timestamp.fromDate(deadline),
      'status': status,
      'attachmentUrls': attachmentUrls,
      'tags': tags,
      'bidCount': bidCount,
      'selectedBidId': selectedBidId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  GigModel copyWith({
    String? title,
    String? description,
    String? category,
    double? budget,
    DateTime? deadline,
    String? status,
    List<String>? attachmentUrls,
    List<String>? tags,
    int? bidCount,
    String? selectedBidId,
  }) {
    return GigModel(
      id: id,
      clientId: clientId,
      clientName: clientName,
      clientAvatarUrl: clientAvatarUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      budget: budget ?? this.budget,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      tags: tags ?? this.tags,
      bidCount: bidCount ?? this.bidCount,
      selectedBidId: selectedBidId ?? this.selectedBidId,
      createdAt: createdAt,
    );
  }

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in-progress';
  bool get isCompleted => status == 'completed';
  int get daysLeft => deadline.difference(DateTime.now()).inDays;

  @override
  List<Object?> get props => [id, title, status, budget, bidCount];
}
