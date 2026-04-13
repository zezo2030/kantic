import '../../domain/entities/trip_participant_entity.dart';

class TripParticipantModel extends TripParticipantEntity {
  const TripParticipantModel({
    required super.name,
    required super.age,
    required super.guardianName,
    required super.guardianPhone,
  });

  factory TripParticipantModel.fromJson(Map<String, dynamic> json) {
    return TripParticipantModel(
      name: json['name'] as String? ?? '',
      age: _asInt(json['age']),
      guardianName: json['guardianName'] as String? ?? '',
      guardianPhone: json['guardianPhone'] as String? ?? '',
    );
  }

  factory TripParticipantModel.fromEntity(TripParticipantEntity entity) {
    return TripParticipantModel(
      name: entity.name,
      age: entity.age,
      guardianName: entity.guardianName,
      guardianPhone: entity.guardianPhone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'guardianName': guardianName,
      'guardianPhone': guardianPhone,
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

