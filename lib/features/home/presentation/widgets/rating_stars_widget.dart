import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RatingStarsWidget extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double starSize;
  final bool showRatingNumber;
  final Color? starColor;
  final Color? emptyStarColor;

  const RatingStarsWidget({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.starSize = 16.0,
    this.showRatingNumber = false,
    this.starColor,
    this.emptyStarColor,
  });

  @override
  Widget build(BuildContext context) {
    final filledStars = rating.floor();
    final hasHalfStar = rating - filledStars >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Display filled stars
        ...List.generate(filledStars, (index) => _buildStar(true)),

        // Display half star if needed
        if (hasHalfStar) _buildHalfStar(),

        // Display empty stars
        ...List.generate(
          maxStars - filledStars - (hasHalfStar ? 1 : 0),
          (index) => _buildStar(false),
        ),

        // Show rating number if requested
        if (showRatingNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: starSize * 0.7,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStar(bool filled) {
    return Icon(
      Icons.star,
      size: starSize,
      color: filled
          ? (starColor ?? AppColors.starColor)
          : (emptyStarColor ?? AppColors.starEmptyColor),
    );
  }

  Widget _buildHalfStar() {
    return Icon(
      Icons.star_half,
      size: starSize,
      color: starColor ?? AppColors.starColor,
    );
  }
}
