import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/offer_entity.dart';

part 'offer_model.g.dart';

@JsonSerializable()
class OfferModel extends OfferEntity {
  const OfferModel({
    required super.id,
    required super.title,
    super.description,
    required super.discountType,
    required super.discountValue,
    super.startsAt,
    super.endsAt,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
      super.imageUrl,
      super.hallName,
      super.branchName,
      super.branchId,
    });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    // معالجة مخصصة لـ discountValue لتجنب خطأ تحويل النوع
    double parsedDiscountValue = 0.0;
    final discountValue = json['discountValue'];

    if (discountValue != null) {
      if (discountValue is num) {
        parsedDiscountValue = discountValue.toDouble();
      } else if (discountValue is String) {
        parsedDiscountValue = double.tryParse(discountValue) ?? 0.0;
      }
    }

    // Extract venue names with fallbacks
    final dynamicHall = json['hall'] is Map
        ? json['hall'] as Map<String, dynamic>
        : null;
    final dynamicBranch = json['branch'] is Map
        ? json['branch'] as Map<String, dynamic>
        : null;
    final dynamicVenue = json['venue'] is Map
        ? json['venue'] as Map<String, dynamic>
        : null;

    // Handle halls arrays (possible keys: 'hals', 'halls') -> take first.name
    String? hallsArrayName;
    final hals = json['hals'];
    final halls = json['halls'];
    if (hals is List && hals.isNotEmpty) {
      final first = hals.first;
      if (first is Map && first['name'] != null) {
        hallsArrayName = first['name'].toString();
      }
    } else if (halls is List && halls.isNotEmpty) {
      final first = halls.first;
      if (first is Map && first['name'] != null) {
        hallsArrayName = first['name'].toString();
      }
    }

    // Hall name: try multiple keys/shapes
    String? parsedHallName = (json['hallName'] ?? json['hallTitle'])
        ?.toString();
    if (parsedHallName == null || parsedHallName.trim().isEmpty) {
      final hallFromMap =
          (dynamicHall?['name'] ??
                  dynamicHall?['title'] ??
                  dynamicHall?['nameAr'] ??
                  dynamicHall?['name_en'])
              ?.toString();
      parsedHallName =
          hallFromMap ?? hallsArrayName ?? dynamicVenue?['name']?.toString();
    }

    // Branch name: try multiple keys/shapes
    String? parsedBranchName = (json['branchName'] ?? json['branchTitle'])
        ?.toString();
    if (parsedBranchName == null || parsedBranchName.trim().isEmpty) {
      if (dynamicBranch != null) {
        parsedBranchName =
            (dynamicBranch['name'] ??
                    dynamicBranch['title'] ??
                    dynamicBranch['nameAr'] ??
                    dynamicBranch['name_en'])
                ?.toString();
      } else if (json['branch'] != null && json['branch'] is String) {
        parsedBranchName = (json['branch'] as String).toString();
      }
    }

    return OfferModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      discountType: json['discountType']?.toString() ?? 'percentage',
      discountValue: parsedDiscountValue,
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(json['startsAt'].toString())
          : null,
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt'].toString())
          : null,
      isActive: json['isActive'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      imageUrl: json['imageUrl']?.toString(),
      hallName: parsedHallName,
      branchName: parsedBranchName,
      branchId: json['branchId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$OfferModelToJson(this);

  factory OfferModel.fromEntity(OfferEntity entity) {
    return OfferModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      discountType: entity.discountType,
      discountValue: entity.discountValue,
      startsAt: entity.startsAt,
      endsAt: entity.endsAt,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      imageUrl: entity.imageUrl,
      hallName: entity.hallName,
      branchName: entity.branchName,
      branchId: entity.branchId,
    );
  }

  OfferEntity toEntity() {
    return OfferEntity(
      id: id,
      title: title,
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      startsAt: startsAt,
      endsAt: endsAt,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      imageUrl: imageUrl,
      hallName: hallName,
      branchName: branchName,
      branchId: branchId,
    );
  }
}
