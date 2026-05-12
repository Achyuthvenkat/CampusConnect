import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BidModel extends Equatable {
  final String id;
  final String gigId;
  final String bidderId;
  final String bidderName;
  final String? bidderAvatarUrl;
  final double bidderRating;
  final double amount;
  final String proposal;
  final int deliveryDays;
  final String status;
  final DateTime createdAt;

  const BidModel({
    required this.id,
    required this.gigId,
    required this.bidderId,
    required this.bidderName,
    this.bidderAvatarUrl,
    this.bidderRating = 0.0,
    required this.amount,
    required this.proposal,
    required this.deliveryDays,
    this.status = 'pending',
    required this.createdAt,
  });

  factory BidModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BidModel(
      id: doc.id,
      gigId: data['gigId'] ?? '',
      bidderId: data['bidderId'] ?? '',
      bidderName: data['bidderName'] ?? '',
      bidderAvatarUrl: data['bidderAvatarUrl'],
      bidderRating: (data['bidderRating'] ?? 0.0).toDouble(),
      amount: (data['amount'] ?? 0).toDouble(),
      proposal: data['proposal'] ?? '',
      deliveryDays: data['deliveryDays'] ?? 1,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gigId': gigId,
      'bidderId': bidderId,
      'bidderName': bidderName,
      'bidderAvatarUrl': bidderAvatarUrl,
      'bidderRating': bidderRating,
      'amount': amount,
      'proposal': proposal,
      'deliveryDays': deliveryDays,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  BidModel copyWith({String? status}) {
    return BidModel(
      id: id,
      gigId: gigId,
      bidderId: bidderId,
      bidderName: bidderName,
      bidderAvatarUrl: bidderAvatarUrl,
      bidderRating: bidderRating,
      amount: amount,
      proposal: proposal,
      deliveryDays: deliveryDays,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  @override
  List<Object?> get props => [id, gigId, bidderId, amount, status];
}
