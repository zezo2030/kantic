// Quote Entity - Domain Layer
import 'package:equatable/equatable.dart';

class QuoteEntity extends Equatable {
  final String branchId;
  final String branchName;
  final Map<String, dynamic> pricing;
  final List<Map<String, dynamic>> addOns;
  final double discount;
  final double totalPrice;
  final bool available;

  const QuoteEntity({
    required this.branchId,
    required this.branchName,
    required this.pricing,
    required this.addOns,
    required this.discount,
    required this.totalPrice,
    required this.available,
  });

  @override
  List<Object?> get props => [
        branchId,
        branchName,
        pricing,
        addOns,
        discount,
        totalPrice,
        available,
      ];
}

