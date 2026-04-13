// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BranchModel _$BranchModelFromJson(Map<String, dynamic> json) => BranchModel(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      location: json['location'] as String,
      capacity: (json['capacity'] as num).toInt(),
      status: json['status'] as String,
      descriptionAr: json['descriptionAr'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      contactPhone: json['contactPhone'] as String?,
      workingHours: json['workingHours'] as Map<String, dynamic>?,
      amenities: (json['amenities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      videoUrl: json['videoUrl'] as String?,
      coverImage: json['coverImage'] as String?,
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      reviewsCount: (json['reviewsCount'] as num?)?.toInt(),
      offers: json['offers'] as List<dynamic>?,
      priceConfig: json['priceConfig'] as Map<String, dynamic>?,
      isDecorated: json['isDecorated'] as bool?,
      hallFeatures: (json['hallFeatures'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      hallImages: (json['hallImages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      hallVideoUrl: json['hallVideoUrl'] as String?,
      hallStatus: json['hallStatus'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
