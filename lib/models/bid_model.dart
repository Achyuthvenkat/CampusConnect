import 'package:cloud_firestore/cloud_firestore.dart';

enum BidStatus { pending, accepted, rejected }

class BidModel {
  final String id;
  final String jobId;
  final String freelancerId;
  final String freelancerName;
  final String? freelancerPhotoUrl;
  final double amount;
  final String proposal;
  final int deliveryDays;
  final BidStatus status;
  final DateTime createdAt;
  final double freelancerRating;

  BidModel({
    required this.id,
    required this.jobId,
    required this.freelancerId,
    required this.freelancerName,
    this.freelancerPhotoUrl,
    required this.amount,
    required this.proposal,
    required this.deliveryDays,
    required this.status,
    required this.createdAt,
    this.freelancerRating = 0,
  });

  factory BidModel.fromMap(Map<String, dynamic> map, String id) {
    return BidModel(
      id: id,
      jobId: map['jobId'] ?? '',
      freelancerId: map['freelancerId'] ?? '',
      freelancerName: map['freelancerName'] ?? '',
      freelancerPhotoUrl: map['freelancerPhotoUrl'],
      amount: (map['amount'] ?? 0).toDouble(),
      proposal: map['proposal'] ?? '',
      deliveryDays: map['deliveryDays'] ?? 7,
      status: BidStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => BidStatus.pending,
      ),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      freelancerRating: (map['freelancerRating'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'freelancerId': freelancerId,
      'freelancerName': freelancerName,
      'freelancerPhotoUrl': freelancerPhotoUrl,
      'amount': amount,
      'proposal': proposal,
      'deliveryDays': deliveryDays,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'freelancerRating': freelancerRating,
    };
  }
}
