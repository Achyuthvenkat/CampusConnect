import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../utils/theme.dart';

class AppRatingBar extends StatelessWidget {
  final double initialRating;
  final ValueChanged<double> onRatingUpdate;
  final bool readOnly;
  final double itemSize;

  const AppRatingBar({
    super.key,
    required this.initialRating,
    required this.onRatingUpdate,
    this.readOnly = false,
    this.itemSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      return RatingBarIndicator(
        rating: initialRating,
        itemBuilder: (_, __) =>
            const Icon(Icons.star, color: Colors.amber),
        itemCount: 5,
        itemSize: itemSize,
      );
    }
    return RatingBar.builder(
      initialRating: initialRating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: itemSize,
      itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
      unratedColor: Colors.grey.shade300,
      onRatingUpdate: onRatingUpdate,
      glow: false,
    );
  }
}

class RatingSummary extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const RatingSummary({
    super.key,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RatingBarIndicator(
              rating: rating,
              itemBuilder: (_, __) =>
                  const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 20,
            ),
            Text(
              '$reviewCount review${reviewCount == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
