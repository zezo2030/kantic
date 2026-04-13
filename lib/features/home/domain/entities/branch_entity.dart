import 'package:equatable/equatable.dart';

class BranchEntity extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final String location;
  final int capacity;
  final String status; // 'active', 'inactive', 'maintenance'
  final String? descriptionAr;
  final String? descriptionEn;
  final String? contactPhone;
  final Map<String, dynamic>? workingHours;
  final List<String>? amenities;
  final String? videoUrl;
  final String? coverImage;
  final List<String>? images;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? reviewsCount;
  final List<dynamic>? offers;
  // Hall-related fields (merged from Hall entity)
  final Map<String, dynamic>? priceConfig;
  final bool? isDecorated;
  final List<String>? hallFeatures;
  final List<String>? hallImages;
  final String? hallVideoUrl;
  final String? hallStatus; // 'available', 'maintenance', 'reserved'
  final DateTime createdAt;
  final DateTime updatedAt;

  const BranchEntity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.location,
    required this.capacity,
    required this.status,
    this.descriptionAr,
    this.descriptionEn,
    this.contactPhone,
    this.workingHours,
    this.amenities,
    this.videoUrl,
    this.coverImage,
    this.images,
    this.latitude,
    this.longitude,
    this.rating,
    this.reviewsCount,
    this.offers,
    this.priceConfig,
    this.isDecorated,
    this.hallFeatures,
    this.hallImages,
    this.hallVideoUrl,
    this.hallStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    nameAr,
    nameEn,
    location,
    capacity,
    status,
    descriptionAr,
    descriptionEn,
    contactPhone,
    workingHours,
    amenities,
    videoUrl,
    coverImage,
    images,
    latitude,
    longitude,
    rating,
    reviewsCount,
    offers,
    priceConfig,
    isDecorated,
    hallFeatures,
    hallImages,
    hallVideoUrl,
    hallStatus,
    createdAt,
    updatedAt,
  ];
}
