import 'package:equatable/equatable.dart';

class TripParticipantEntity extends Equatable {
  final String name;
  final int age;
  final String guardianName;
  final String guardianPhone;

  const TripParticipantEntity({
    required this.name,
    required this.age,
    required this.guardianName,
    required this.guardianPhone,
  });

  TripParticipantEntity copyWith({
    String? name,
    int? age,
    String? guardianName,
    String? guardianPhone,
  }) {
    return TripParticipantEntity(
      name: name ?? this.name,
      age: age ?? this.age,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
    );
  }

  @override
  List<Object?> get props => [name, age, guardianName, guardianPhone];
}

