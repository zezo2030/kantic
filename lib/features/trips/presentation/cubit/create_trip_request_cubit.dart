import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/create_trip_request_input.dart';
import '../../domain/entities/trip_addon_entity.dart';
import '../../domain/usecases/create_trip_request_usecase.dart';
import 'create_trip_request_state.dart';

class CreateTripRequestCubit extends Cubit<CreateTripRequestState> {
  CreateTripRequestCubit({
    required this.createTripRequestUseCase,
  }) : _selectedDate = DateTime.now().add(const Duration(days: 1)),
       super(CreateTripRequestState.initial());

  final CreateTripRequestUseCase createTripRequestUseCase;

  String? selectedBranchId;
  String schoolName = '';
  DateTime _selectedDate;
  String? preferredTime;
  int? durationHours = 2;
  String? specialRequirements;
  String? paymentMethod;
  /// `full` or `deposit` — required by API.
  String paymentOption = 'full';
  final List<TripAddOnEntity> _addOns = [];

  int minimumStudentsForCreate = 35;
  int studentsCount = 35;
  double ticketPricePerStudent = 45;
  double depositPercent = 20;

  DateTime get preferredDate => _selectedDate;
  List<TripAddOnEntity> get addOns => List.unmodifiable(_addOns);

  bool get isValidBasicInfo =>
      selectedBranchId != null &&
      selectedBranchId!.isNotEmpty &&
      schoolName.isNotEmpty &&
      preferredTime != null &&
      preferredTime!.isNotEmpty &&
      minimumStudentsForCreate > 0 &&
      studentsCount >= minimumStudentsForCreate;

  void updateSelectedBranchId(String? value) {
    selectedBranchId = value;
  }

  void updateSchoolName(String value) {
    schoolName = value;
  }

  void updateStudentsCount(int value) {
    studentsCount = value;
  }

  void updatePreferredDate(DateTime value) {
    _selectedDate = value;
  }

  void updatePreferredTime(String? value) {
    preferredTime = value;
  }

  void updateDurationHours(int? value) {
    durationHours = value;
  }

  void updateSpecialRequirements(String? value) {
    specialRequirements = value;
  }

  void updatePaymentMethod(String? value) {
    paymentMethod = value;
  }

  void updatePaymentOption(String value) {
    paymentOption = value == 'deposit' ? 'deposit' : 'full';
  }

  void applyTripConfig(Map<String, dynamic> cfg) {
    final m = cfg['minimumStudents'];
    if (m is int) {
      minimumStudentsForCreate = m;
    } else if (m is num) {
      minimumStudentsForCreate = m.toInt();
    }
    if (studentsCount < minimumStudentsForCreate) {
      studentsCount = minimumStudentsForCreate;
    }

    final dynamic ticketPriceRaw =
        cfg['pricePerStudent'] ?? cfg['ticketPrice'] ?? cfg['studentTicketPrice'];
    if (ticketPriceRaw is num) {
      ticketPricePerStudent = ticketPriceRaw.toDouble();
    } else if (ticketPriceRaw is String) {
      ticketPricePerStudent =
          double.tryParse(ticketPriceRaw) ?? ticketPricePerStudent;
    }

    final dynamic depositRaw =
        cfg['depositPercent'] ?? cfg['depositPercentage'] ?? cfg['downPaymentPercent'];
    if (depositRaw is num) {
      depositPercent = depositRaw.toDouble();
    } else if (depositRaw is String) {
      depositPercent = double.tryParse(depositRaw) ?? depositPercent;
    }
  }

  void addAddon(TripAddOnEntity addon) {
    _addOns.removeWhere((a) => a.id == addon.id);
    _addOns.add(addon);
  }

  void removeAddon(String addonId) {
    _addOns.removeWhere((addon) => addon.id == addonId);
  }

  Future<void> submit() async {
    if (!isValidBasicInfo) {
      emit(
        state.copyWith(
          errorMessage:
              'يرجى إكمال اسم المدرسة واختيار الفرع والموعد، والتأكد من تحميل إعدادات الرحلة.',
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final input = CreateTripRequestInput(
        branchId: selectedBranchId,
        schoolName: schoolName,
        studentsCount: studentsCount,
        preferredDate: _selectedDate,
        preferredTime: preferredTime,
        durationHours: durationHours,
        specialRequirements: specialRequirements,
        addOns: _addOns,
        paymentMethod: paymentMethod,
        paymentOption: paymentOption,
      );

      final requestId = await createTripRequestUseCase(input);

      emit(state.copyWith(isSubmitting: false, requestId: requestId));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }
}
