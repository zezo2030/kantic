// AddOn Entity - Domain Layer
import 'package:equatable/equatable.dart';

class AddOnEntity extends Equatable {
  final String id;
  final String name;
  final double price;
  final int quantity;

  const AddOnEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  @override
  List<Object?> get props => [id, name, price, quantity];
}

