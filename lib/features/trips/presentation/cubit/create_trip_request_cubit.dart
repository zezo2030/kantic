import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/create_trip_request_input.dart';
import '../../domain/entities/trip_addon_entity.dart';
import '../../domain/entities/trip_participants_upload_entity.dart';
import '../../domain/entities/submit_trip_request_input.dart';
import '../../domain/usecases/create_trip_request_usecase.dart';
import '../../domain/usecases/submit_trip_request_usecase.dart';
import '../../domain/usecases/upload_trip_participants_usecase.dart';
import 'create_trip_request_state.dart';

class CreateTripRequestCubit extends Cubit<CreateTripRequestState> {
  CreateTripRequestCubit({
    required this.createTripRequestUseCase,
    required this.uploadTripParticipantsUseCase,
    required this.submitTripRequestUseCase,
  }) : _selectedDate = DateTime.now().add(const Duration(days: 1)),
       super(CreateTripRequestState.initial());

  final CreateTripRequestUseCase createTripRequestUseCase;
  final UploadTripParticipantsUseCase uploadTripParticipantsUseCase;
  final SubmitTripRequestUseCase submitTripRequestUseCase;

  String? selectedBranchId;
  String schoolName = '';
  int studentsCount = 0; // Will be set from Excel file
  int? accompanyingAdults = 2;
  DateTime _selectedDate;
  String? preferredTime;
  int? durationHours = 2;
  String contactPersonName = '';
  String contactPhone = '';
  String? contactEmail;
  String? specialRequirements;
  String? paymentMethod;
  Uint8List? participantsFileBytes;
  String? participantsFileName;
  final List<TripAddOnEntity> _addOns = [];

  DateTime get preferredDate => _selectedDate;
  List<TripAddOnEntity> get addOns => List.unmodifiable(_addOns);

  bool get isValidBasicInfo =>
      selectedBranchId != null &&
      selectedBranchId!.isNotEmpty &&
      schoolName.isNotEmpty &&
      contactPersonName.isNotEmpty &&
      contactPhone.length >= 8 &&
      participantsFileBytes != null;

  void updateSelectedBranchId(String? value) {
    selectedBranchId = value;
  }

  void updateSchoolName(String value) {
    schoolName = value;
  }

  void updateStudentsCount(int value) {
    studentsCount = value;
  }

  void updateAccompanyingAdults(int? value) {
    accompanyingAdults = value;
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

  void updateContactPersonName(String value) {
    contactPersonName = value;
  }

  void updateContactPhone(String value) {
    contactPhone = value;
  }

  void updateContactEmail(String? value) {
    contactEmail = value;
  }

  void updateSpecialRequirements(String? value) {
    specialRequirements = value;
  }

  void updatePaymentMethod(String? value) {
    paymentMethod = value;
  }

  void addAddon(TripAddOnEntity addon) {
    _addOns.removeWhere((a) => a.id == addon.id);
    _addOns.add(addon);
  }

  void removeAddon(String addonId) {
    _addOns.removeWhere((addon) => addon.id == addonId);
  }

  void updateParticipantsFile(Uint8List bytes, String fileName) {
    participantsFileBytes = bytes;
    participantsFileName = fileName;
  }

  Future<void> submit() async {
    if (!isValidBasicInfo) {
      emit(
        state.copyWith(
          errorMessage:
              'يرجى إكمال بيانات المدرسة ومعلومات التواصل واختيار الفرع ورفع ملف الطلاب.',
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final input = CreateTripRequestInput(
        branchId: selectedBranchId,
        schoolName: schoolName,
        studentsCount: studentsCount > 0
            ? studentsCount
            : null, // Optional, will be set from Excel
        accompanyingAdults: accompanyingAdults,
        preferredDate: _selectedDate,
        preferredTime: preferredTime,
        durationHours: durationHours,
        contactPersonName: contactPersonName,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        specialRequirements: specialRequirements,
        addOns: _addOns,
        paymentMethod: paymentMethod,
      );

      // 1. Create Request
      final requestId = await createTripRequestUseCase(input);

      // 2. Upload Participants Document File
      if (participantsFileBytes != null && participantsFileName != null) {
        final count = await uploadTripParticipantsUseCase(
          requestId: requestId,
          upload: TripParticipantsUploadEntity(
            bytes: participantsFileBytes!,
            filename: participantsFileName!,
          ),
        );
        studentsCount = count;
      }

      // 3. Submit Request to Under Review
      await submitTripRequestUseCase(
        requestId: requestId,
        input: const SubmitTripRequestInput(),
      );

      emit(state.copyWith(isSubmitting: false, requestId: requestId));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }
}
