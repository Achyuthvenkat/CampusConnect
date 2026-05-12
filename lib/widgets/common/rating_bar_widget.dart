import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:campus_connect/app/theme/app_colors.dart';

class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double itemSize;
  final bool showText;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.itemSize = 16,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBarIndicator(
          rating: rating.clamp(0.001, 5.0),
          itemBuilder: (context, _) => const Icon(
            Icons.star_rounded,
            color: AppColors.accentOrange,
          ),
          itemCount: 5,
          itemSize: itemSize,
          unratedColor: AppColors.divider,
        ),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: itemSize * 0.85,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveRating extends StatelessWidget {
  final double initialRating;
  final void Function(double) onRatingUpdate;
  final double itemSize;

  const InteractiveRating({
    super.key,
    this.initialRating = 0,
    required this.onRatingUpdate,
    this.itemSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: initialRating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: false,
      itemCount: 5,
      itemSize: itemSize,
      glow: false,
      itemBuilder: (context, _) => const Icon(
        Icons.star_rounded,
        color: AppColors.accentOrange,
      ),
      onRatingUpdate: onRatingUpdate,
    );
  }
}
