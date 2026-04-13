import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class RatingsSection extends StatelessWidget {
  final double? rating;
  final int? reviewsCount;

  const RatingsSection({super.key, this.rating, this.reviewsCount});

  @override
  Widget build(BuildContext context) {
    if (rating == null) return const SizedBox.shrink();
    final rounded = (rating! * 10).round() / 10.0;
    return Row(
      children: [
        const Icon(Iconsax.star1, color: Color(0xFFFFC107), size: 20),
        const SizedBox(width: 6),
        Text(
          '$rounded',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        if (reviewsCount != null) ...[
          const SizedBox(width: 6),
          Text(
            '($reviewsCount)',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ],
    );
  }
}
