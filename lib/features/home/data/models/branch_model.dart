import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/branch_entity.dart';

part 'branch_model.g.dart';

@JsonSerializable(createToJson: false)
class BranchModel extends BranchEntity {
  const BranchModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.location,
    required super.capacity,
    required super.status,
    super.descriptionAr,
    super.descriptionEn,
    super.contactPhone,
    super.workingHours,
    super.amenities,
    super.videoUrl,
    super.coverImage,
    super.images,
    super.latitude,
    super.longitude,
    super.rating,
    super.reviewsCount,
    super.offers,
    super.priceConfig,
    super.isDecorated,
    super.hallFeatures,
    super.hallImages,
    super.hallVideoUrl,
    super.hallStatus,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    // التحقق من وجود السعة ومعالجتها بشكل صحيح
    final capacity = json['capacity'];
    int parsedCapacity = 0;

    if (capacity != null) {
      if (capacity is int) {
        parsedCapacity = capacity;
      } else if (capacity is double) {
        parsedCapacity = capacity.toInt();
      } else if (capacity is String) {
        final cleanValue = capacity.trim().replaceAll(RegExp(r'[^\d]'), '');
        parsedCapacity = int.tryParse(cleanValue) ?? 0;
      }
    }

    return BranchModel(
      id: json['id']?.toString() ?? '',
      nameAr: (json['name_ar'] ?? json['nameAr'] ?? '').toString(),
      nameEn: (json['name_en'] ?? json['nameEn'] ?? '').toString(),
      location: json['location']?.toString() ?? '',
      capacity: parsedCapacity,
      status: json['status']?.toString() ?? 'inactive',
      descriptionAr: (json['description_ar'] ?? json['descriptionAr'])
          ?.toString(),
      descriptionEn: (json['description_en'] ?? json['descriptionEn'])
          ?.toString(),
      contactPhone: (json['contact_phone'] ?? json['contactPhone'])?.toString(),
      workingHours:
          (json['workingHours'] ?? json['working_hours'])
              as Map<String, dynamic>?,
      amenities: (json['amenities'] as List<dynamic>?)
          ?.map((e) => e?.toString() ?? '')
          .toList(),
      videoUrl: json['videoUrl']?.toString(),
      coverImage: (json['cover'] ?? json['coverImage'])?.toString(),
      images: ((json['images'] ?? json['gallery']) as List<dynamic>?)
          ?.map((e) => e?.toString() ?? '')
          .toList(),
      latitude:
          _parseDouble(json['lat'] ?? json['latitude']) ??
          _coordFromMap(json['coordinates'], const ['lat', 'latitude']) ??
          _coordFromMap(json['geo'], const ['lat', 'latitude']),
      longitude:
          _parseDouble(json['lng'] ?? json['longitude']) ??
          _coordFromMap(json['coordinates'], const ['lng', 'longitude']) ??
          _coordFromMap(json['geo'], const ['lng', 'longitude']),
      rating: _parseDouble(json['rating']),
      reviewsCount: _parseInt(json['reviewsCount'] ?? json['reviews_count']),
      offers: (json['offers'] as List<dynamic>?)?.toList(),
      priceConfig: (json['priceConfig'] ?? json['price_config']) as Map<String, dynamic>?,
      isDecorated: json['isDecorated'] ?? json['is_decorated'] ?? false,
      hallFeatures: (json['hallFeatures'] ?? json['hall_features'] ?? json['features']) != null
          ? ((json['hallFeatures'] ?? json['hall_features'] ?? json['features']) as List<dynamic>)
              .map((e) => e?.toString() ?? '')
              .toList()
          : null,
      hallImages: (json['hallImages'] ?? json['hall_images']) != null
          ? ((json['hallImages'] ?? json['hall_images']) as List<dynamic>)
              .map((e) => e?.toString() ?? '')
              .toList()
          : null,
      hallVideoUrl: (json['hallVideoUrl'] ?? json['hall_video_url'])?.toString(),
      hallStatus: (json['hallStatus'] ?? json['hall_status'] ?? 'available')?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.trim().replaceAll(',', '.');
      return double.tryParse(s);
    }
    return null;
  }

  static double? _coordFromMap(dynamic map, List<String> keys) {
    if (map is! Map) return null;
    final m = Map<String, dynamic>.from(map);
    for (final k in keys) {
      final d = _parseDouble(m[k]);
      if (d != null) return d;
    }
    return null;
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^\d]'), ''));
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'location': location,
      'capacity': capacity,
      'status': status,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'contact_phone': contactPhone,
      'working_hours': workingHours,
      'amenities': amenities,
      'videoUrl': videoUrl,
      'cover': coverImage,
      'images': images,
      'lat': latitude,
      'lng': longitude,
      'rating': rating,
      'reviews_count': reviewsCount,
      'offers': offers,
      'priceConfig': priceConfig,
      'isDecorated': isDecorated,
      'hallFeatures': hallFeatures,
      'hallImages': hallImages,
      'hallVideoUrl': hallVideoUrl,
      'hallStatus': hallStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BranchModel.fromEntity(BranchEntity entity) {
    return BranchModel(
      id: entity.id,
      nameAr: entity.nameAr,
      nameEn: entity.nameEn,
      location: entity.location,
      capacity: entity.capacity,
      status: entity.status,
      descriptionAr: entity.descriptionAr,
      descriptionEn: entity.descriptionEn,
      contactPhone: entity.contactPhone,
      workingHours: entity.workingHours,
      amenities: entity.amenities,
      videoUrl: entity.videoUrl,
      coverImage: entity.coverImage,
      images: entity.images,
      latitude: entity.latitude,
      longitude: entity.longitude,
      rating: entity.rating,
      reviewsCount: entity.reviewsCount,
      offers: entity.offers,
      priceConfig: entity.priceConfig,
      isDecorated: entity.isDecorated,
      hallFeatures: entity.hallFeatures,
      hallImages: entity.hallImages,
      hallVideoUrl: entity.hallVideoUrl,
      hallStatus: entity.hallStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  BranchEntity toEntity() {
    return BranchEntity(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      location: location,
      capacity: capacity,
      status: status,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
      contactPhone: contactPhone,
      workingHours: workingHours,
      amenities: amenities,
      videoUrl: videoUrl,
      coverImage: coverImage,
      images: images,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      reviewsCount: reviewsCount,
      offers: offers,
      priceConfig: priceConfig,
      isDecorated: isDecorated,
      hallFeatures: hallFeatures,
      hallImages: hallImages,
      hallVideoUrl: hallVideoUrl,
      hallStatus: hallStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
