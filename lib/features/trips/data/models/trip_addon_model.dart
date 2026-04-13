import '../../domain/entities/trip_addon_entity.dart';

class TripAddOnModel extends TripAddOnEntity {
  const TripAddOnModel({
    required super.id,
    required super.name,
    required super.price,
    required super.quantity,
  });

  factory TripAddOnModel.fromJson(Map<String, dynamic> json) {
    return TripAddOnModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: _asInt(json['price']),
      quantity: _asInt(json['quantity'], fallback: 1),
    );
  }

  factory TripAddOnModel.fromEntity(TripAddOnEntity entity) {
    return TripAddOnModel(
      id: entity.id,
      name: entity.name,
      price: entity.price,
      quantity: entity.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}

