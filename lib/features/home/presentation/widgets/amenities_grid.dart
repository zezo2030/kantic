import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/branch_entity.dart';

class AmenitiesGrid extends StatelessWidget {
  final BranchEntity branch;

  const AmenitiesGrid({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    if (branch.amenities == null || branch.amenities!.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'amenities'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'branch_amenities'.tr(),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'amenities'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: branch.amenities!.map((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getAmenityIcon(amenity),
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        amenity,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final amenityLower = amenity.toLowerCase();

    if (amenityLower.contains('wifi') || amenityLower.contains('wi-fi')) {
      return Icons.wifi;
    } else if (amenityLower.contains('parking')) {
      return Icons.local_parking;
    } else if (amenityLower.contains('air') ||
        amenityLower.contains('conditioning')) {
      return Icons.ac_unit;
    } else if (amenityLower.contains('food') ||
        amenityLower.contains('restaurant')) {
      return Icons.restaurant;
    } else if (amenityLower.contains('drink') ||
        amenityLower.contains('coffee')) {
      return Icons.local_cafe;
    } else if (amenityLower.contains('security')) {
      return Icons.security;
    } else if (amenityLower.contains('clean') ||
        amenityLower.contains('hygiene')) {
      return Icons.cleaning_services;
    } else if (amenityLower.contains('music') ||
        amenityLower.contains('sound')) {
      return Icons.music_note;
    } else if (amenityLower.contains('tv') ||
        amenityLower.contains('television')) {
      return Icons.tv;
    } else if (amenityLower.contains('game') ||
        amenityLower.contains('gaming')) {
      return Icons.games;
    } else if (amenityLower.contains('smoking')) {
      return Icons.smoking_rooms;
    } else if (amenityLower.contains('non-smoking') ||
        amenityLower.contains('no smoking')) {
      return Icons.smoke_free;
    } else if (amenityLower.contains('wheelchair') ||
        amenityLower.contains('accessibility')) {
      return Icons.accessible;
    } else if (amenityLower.contains('kids') ||
        amenityLower.contains('children')) {
      return Icons.child_care;
    } else if (amenityLower.contains('pet') ||
        amenityLower.contains('animal')) {
      return Icons.pets;
    } else {
      return Icons.star;
    }
  }
}
