import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

import '../../../booking/presentation/widgets/duration_selector.dart';
import '../../../booking/presentation/widgets/slot_selector.dart';
import '../../../booking/domain/entities/time_slot_entity.dart';
import '../../../booking/presentation/cubit/booking_cubit.dart';
import '../../../booking/presentation/cubit/booking_state.dart';
import '../../../booking/di/booking_injection.dart' as booking_di;
import '../../di/trips_injection.dart' as trips_di;
import '../../domain/entities/trip_addon_entity.dart';
import '../cubit/create_trip_request_cubit.dart';
import '../cubit/create_trip_request_state.dart';

class TripRequestWizardPage extends StatefulWidget {
  final String? branchId;

  const TripRequestWizardPage({super.key, this.branchId});

  @override
  State<TripRequestWizardPage> createState() => _TripRequestWizardPageState();
}

class _TripRequestWizardPageState extends State<TripRequestWizardPage> {
  // Current step (0-3)
  int _currentStep = 0;
  final int _totalSteps = 4;

  late final CreateTripRequestCubit _cubit;
  late final BookingCubit _bookingCubit; // For slot fetching
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _specialRequestController = TextEditingController();

  // Branch selection state
  List<Map<String, dynamic>> availableBranches = [];
  bool isLoadingBranches = false;
  String? branchesError;

  // Slot-related state
  List<TimeSlotEntity> availableSlots = [];
  TimeSlotEntity? selectedSlot;
  bool isLoadingSlots = false;
  String? slotsError;
  int slotMinutes = 60;

  @override
  void initState() {
    super.initState();
    _cubit = trips_di.sl<CreateTripRequestCubit>();
    _bookingCubit = booking_di.sl(); // Get booking cubit for slot fetching
    _loadBranches(); // Load available branches

    // If branchId is provided, set it immediately and fetch slots
    if (widget.branchId != null) {
      _cubit.updateSelectedBranchId(widget.branchId!);
      // Fetch slots after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchSlotsForDate();
      });
    }
  }

  @override
  void dispose() {
    _cubit.close();
    _bookingCubit.close();
    _schoolNameController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _specialRequestController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    setState(() {
      isLoadingBranches = true;
      branchesError = null;
    });

    try {
      final response = await DioClient.instance.get(
        '${ApiConstants.baseUrl}/content/branches',
      );
      if (response.data is List) {
        setState(() {
          availableBranches = List<Map<String, dynamic>>.from(response.data);
          isLoadingBranches = false;
        });
      } else {
        setState(() {
          branchesError = 'Failed to load branches';
          isLoadingBranches = false;
        });
      }
    } catch (e) {
      setState(() {
        branchesError = 'Failed to load branches: ${e.toString()}';
        isLoadingBranches = false;
        // Fallback mock data
        availableBranches = [
          {
            'id': '1',
            'name_ar': 'trip_main_branch'.tr(),
            'name_en': 'trip_main_branch_en'.tr(),
          },
          {
            'id': '2',
            'name_ar': 'trip_north_branch'.tr(),
            'name_en': 'trip_north_branch_en'.tr(),
          },
          {
            'id': '3',
            'name_ar': 'trip_south_branch'.tr(),
            'name_en': 'trip_south_branch_en'.tr(),
          },
        ];
      });
    }
  }

  void _fetchSlotsForDate() {
    final date = _cubit.preferredDate;
    final branchId = _cubit.selectedBranchId;

    // Only fetch slots if we have both date and selected branch
    if (branchId == null || branchId.isEmpty) {
      setState(() {
        availableSlots = [];
        slotsError = null;
        selectedSlot = null;
      });
      return;
    }

    final normalizedDate = DateTime(date.year, date.month, date.day);
    // Use default value for persons since studentsCount will be set from Excel
    _bookingCubit.fetchBranchSlots(
      branchId: branchId,
      date: normalizedDate,
      durationHours: _cubit.durationHours ?? 2,
      persons: _cubit.studentsCount > 0
          ? _cubit.studentsCount
          : 1, // Default to 1 if not set
    );
  }

  void _onSlotSelected(TimeSlotEntity slot) {
    setState(() {
      selectedSlot = slot;
      _cubit.updatePreferredTime(
        '${slot.start.hour.toString().padLeft(2, '0')}:${slot.start.minute.toString().padLeft(2, '0')}',
      );
    });
  }

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0: // School info - only basic validation needed to proceed
        return _cubit.schoolName.isNotEmpty;
      case 1: // Branch
        return _cubit.selectedBranchId != null &&
            _cubit.selectedBranchId!.isNotEmpty;
      case 2: // Date, Time & Duration
        return selectedSlot != null;
      case 3: // Contact & Review - can always proceed if reached
        return true;
      default:
        return false;
    }
  }

  bool _isAllDataComplete() {
    final isComplete =
        _cubit.schoolName.isNotEmpty &&
        _cubit.selectedBranchId != null &&
        _cubit.selectedBranchId!.isNotEmpty &&
        selectedSlot != null &&
        _cubit.contactPersonName.isNotEmpty &&
        _cubit.contactPhone.length >= 8 &&
        _cubit.participantsFileBytes != null;

    return isComplete;
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1 && _canProceedFromStep(_currentStep)) {
      final fromStep = _currentStep;
      setState(() => _currentStep++);

      // When moving from Branch selection (step 1) to Date/Time (step 2),
      // automatically fetch slots for the selected branch
      if (fromStep == 1 && _currentStep == 2) {
        if (_cubit.selectedBranchId != null &&
            _cubit.selectedBranchId!.isNotEmpty &&
            availableSlots.isEmpty &&
            !isLoadingSlots) {
          _fetchSlotsForDate();
        }
      }
    } else {
      // Force rebuild to update button state
      setState(() {});
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'school_info'.tr();
      case 1:
        return 'branch_selection'.tr();
      case 2:
        return 'booking_step_date_time'.tr();
      case 3:
        return 'contact_addons_review'.tr();
      default:
        return '';
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Step titles
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Column(
                  children: [
                    // Circle indicator
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isActive
                            ? AppColors.primaryRed
                            : Colors.grey.shade200,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Step title
                    Text(
                      _getStepTitle(index),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive
                            ? AppColors.primaryRed
                            : Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: List.generate(_totalSteps - 1, (index) {
              final isCompleted = index < _currentStep;
              return Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primaryRed
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0SchoolInfo();
      case 1:
        return _buildStep1BranchHall();
      case 2:
        return _buildStep2DateTime();
      case 3:
        return _buildStep3ContactReview();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _bookingCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<CreateTripRequestCubit, CreateTripRequestState>(
            listener: (context, state) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              } else if (state.requestId != null) {
                Navigator.pop(context, state.requestId);
              }
            },
          ),
          BlocListener<BookingCubit, BookingState>(
            listener: (context, bookingState) {
              // Handle booking cubit state changes for slots
              if (bookingState is SlotsLoading) {
                setState(() {
                  isLoadingSlots = true;
                  slotsError = null;
                });
              } else if (bookingState is SlotsLoaded) {
                setState(() {
                  isLoadingSlots = false;
                  slotsError = null;
                  slotMinutes = bookingState.branchSlots.slotMinutes;
                  availableSlots = bookingState.branchSlots.slots;
                });

                // Auto-select first available slot if none selected
                if (selectedSlot == null && availableSlots.isNotEmpty) {
                  final availableSlotsList = availableSlots
                      .where((slot) => slot.available)
                      .toList();
                  final slotToSelect = availableSlotsList.isNotEmpty
                      ? availableSlotsList.first
                      : availableSlots.first;
                  _onSlotSelected(slotToSelect);
                }
              } else if (bookingState is SlotsError) {
                setState(() {
                  isLoadingSlots = false;
                  slotsError = bookingState.message;
                  availableSlots = [];
                });
              }
            },
          ),
        ],
        child: BlocBuilder<CreateTripRequestCubit, CreateTripRequestState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: AppColors.backgroundColor,
              appBar: AppBar(
                backgroundColor: AppColors.backgroundColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                iconTheme: const IconThemeData(color: AppColors.textPrimary),
                title: Text(
                  'create_trip_request'.tr(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: true,
              ),
              body: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryRed,
                        width: 2,
                      ),
                    ),
                    prefixIconColor: AppColors.textSecondary,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Progress Indicator
                      _buildProgressIndicator(),

                      // Step Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: _buildStepContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _buildBottomBar(state.isSubmitting),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isSubmitting) {
    final canProceed = _canProceedFromStep(_currentStep);
    final isLastStep = _currentStep == _totalSteps - 1;
    final canSubmit = isLastStep ? _isAllDataComplete() : canProceed;

    // Debug logging for submit button state
    if (isLastStep) {
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'previous'.tr(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

            if (_currentStep > 0) const SizedBox(width: 12),

            // Next/Submit button
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: canSubmit && !isSubmitting
                      ? AppColors.primaryGradient
                      : null,
                  color: canSubmit && !isSubmitting
                      ? null
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: canSubmit && !isSubmitting
                      ? (isLastStep ? _submit : _nextStep)
                      : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          isLastStep
                              ? 'submit_new_trip'.tr()
                              : 'continue_step'.tr(),
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0SchoolInfo() {
    return _buildBasicInfoSection(context);
  }

  Widget _buildStep1BranchHall() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Branch selection
        _buildBranchHallSection(),
      ],
    );
  }

  Widget _buildStep2DateTime() {
    return _buildScheduleSection(context);
  }

  Widget _buildStep3ContactReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contact info
        _buildContactSection(context),
        const SizedBox(height: 16),

        // Add-ons
        _buildAddOnsSection(context),
        const SizedBox(height: 16),

        // Notes
        _buildNotesSection(context),
        const SizedBox(height: 16),

        // File Upload
        _buildFileUploadSection(context),
        const SizedBox(height: 16),

        // Summary
        _buildTripSummary(),
        const SizedBox(height: 24), // Extra space at bottom
      ],
    );
  }

  Widget _buildBranchHallSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.building,
                    color: AppColors.primaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'branch_selection'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Branch Selection
            if (isLoadingBranches)
              const Center(child: CircularProgressIndicator())
            else if (branchesError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        branchesError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _cubit.selectedBranchId,
                decoration: InputDecoration(
                  labelText: 'select_branch'.tr(),
                  prefixIcon: const Icon(Icons.business),
                ),
                items: availableBranches.map((branch) {
                  final nameAr = (branch['name_ar'] ?? branch['nameAr'] ?? '')
                      .toString();
                  final nameEn = (branch['name_en'] ?? branch['nameEn'] ?? '')
                      .toString();
                  final displayName = nameAr.isNotEmpty
                      ? nameAr
                      : (nameEn.isNotEmpty ? nameEn : 'unknown_branch'.tr());
                  return DropdownMenuItem<String>(
                    value: branch['id'] as String,
                    child: Text(displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  _cubit.updateSelectedBranchId(value);
                  if (value != null && value.isNotEmpty) {
                    _fetchSlotsForDate();
                  } else {
                    setState(() {
                      availableSlots = [];
                      selectedSlot = null;
                    });
                  }
                  setState(() {});
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_select_branch'.tr();
                  }
                  return null;
                },
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummary() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.document_text,
                    color: AppColors.primaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'trip_summary'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // School info
            if (_cubit.schoolName.isNotEmpty)
              _buildSummaryRow('school_name'.tr(), _cubit.schoolName),

            // Students count - will be set from Excel file
            _buildSummaryRow(
              'students_count'.tr(),
              _cubit.studentsCount > 0
                  ? '${_cubit.studentsCount} ${'persons'.tr()}'
                  : 'will_be_determined_from_excel'.tr(),
            ),

            // Branch
            if (_cubit.selectedBranchId != null)
              _buildSummaryRow(
                'branch'.tr(),
                _getBranchName(_cubit.selectedBranchId!),
              ),

            // Date and Time
            if (selectedSlot != null)
              _buildSummaryRow(
                'date_time'.tr(),
                DateFormat('yyyy/MM/dd HH:mm').format(selectedSlot!.start),
              ),

            // Duration
            if (_cubit.durationHours != null)
              _buildSummaryRow(
                'duration'.tr(),
                '${_cubit.durationHours} ${'hours'.tr()}',
              ),

            // Contact info
            if (_cubit.contactPersonName.isNotEmpty)
              _buildSummaryRow('contact_person'.tr(), _cubit.contactPersonName),

            if (_cubit.contactPhone.isNotEmpty)
              _buildSummaryRow('contact_phone'.tr(), _cubit.contactPhone),

            // Add-ons
            if (_cubit.addOns.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'selected_addons'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ..._cubit.addOns.map(
                    (addon) => Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 4),
                      child: Text('• ${addon.name} ×${addon.quantity}'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                const Icon(
                  Iconsax.arrow_right_3,
                  size: 14,
                  color: AppColors.primaryRed,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBranchName(String branchId) {
    final branch = availableBranches.firstWhere(
      (b) => b['id'] == branchId,
      orElse: () => {
        'nameAr': 'unknown_branch'.tr(),
        'nameEn': 'unknown_branch_en'.tr(),
      },
    );
    return (branch['name_ar'] ?? branch['nameAr'] ?? 'unknown_branch'.tr())
        .toString();
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.teacher,
                    color: AppColors.primaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'school_details'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _schoolNameController,
              decoration: InputDecoration(
                labelText: 'school_name'.tr(),
                prefixIcon: const Icon(Icons.school_outlined),
              ),
              onChanged: (value) {
                _cubit.updateSchoolName(value);
                setState(() {}); // Rebuild to update Next button state
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'provide_school_name'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Accompanying Adults Section
            TextFormField(
              initialValue: _cubit.accompanyingAdults?.toString(),
              decoration: InputDecoration(
                labelText: 'accompanying_adults'.tr(),
                prefixIcon: const Icon(Icons.family_restroom_outlined),
                hintText: 'optional'.tr(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _cubit.updateAccompanyingAdults(int.tryParse(value));
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection(BuildContext context) {
    final formattedDate = DateFormat.yMMMMd(
      context.locale.toString(),
    ).format(_cubit.preferredDate);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.calendar_1,
                    color: AppColors.primaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'trip_schedule'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text('preferred_date'.tr()),
              subtitle: Text(formattedDate),
              onTap: () async {
                final now = DateTime.now();
                final tomorrow = DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).add(const Duration(days: 1));

                DateTime initial = _cubit.preferredDate;
                if (initial.isBefore(tomorrow)) {
                  initial = tomorrow;
                }

                final picked = await showDatePicker(
                  context: context,
                  firstDate: tomorrow,
                  lastDate: now.add(const Duration(days: 365)),
                  initialDate: initial,
                );
                if (picked != null) {
                  _cubit.updatePreferredDate(picked);
                  selectedSlot = null; // Reset selected slot when date changes
                  // Fetch slots only if branch is also selected
                  if (_cubit.selectedBranchId != null &&
                      _cubit.selectedBranchId!.isNotEmpty) {
                    _fetchSlotsForDate();
                  } else {
                    setState(() {
                      availableSlots = [];
                    });
                  }
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 8),
            SlotSelector(
              slots: availableSlots,
              selectedSlot: selectedSlot,
              slotMinutes: slotMinutes,
              selectedDurationHours: _cubit.durationHours ?? 2,
              isLoading: isLoadingSlots,
              errorMessage: slotsError,
              onSlotSelected: _onSlotSelected,
            ),
            const SizedBox(height: 16),
            DurationSelector(
              selectedDuration: _cubit.durationHours ?? 2,
              maxDuration: 8,
              onDurationChanged: (value) {
                _cubit.updateDurationHours(value);
                // Refetch slots if branch is selected
                if (_cubit.selectedBranchId != null &&
                    _cubit.selectedBranchId!.isNotEmpty) {
                  _fetchSlotsForDate();
                }
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.call,
                    color: AppColors.primaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'contact_information'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactPersonController,
              decoration: InputDecoration(
                labelText: 'contact_person'.tr(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              onChanged: (value) {
                _cubit.updateContactPersonName(value);
                setState(() {});
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'provide_contact_person'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactPhoneController,
              decoration: InputDecoration(
                labelText: 'contact_phone'.tr(),
                prefixIcon: const Icon(Icons.phone_enabled_outlined),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                _cubit.updateContactPhone(value);
                setState(() {});
              },
              validator: (value) {
                if (value == null || value.trim().length < 8) {
                  return 'provide_contact_phone'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactEmailController,
              decoration: InputDecoration(
                labelText: 'contact_email'.tr(),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                _cubit.updateContactEmail(value);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOnsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.category,
                    color: AppColors.primaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'trip_addons'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('trip_addons_hint'.tr(), style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            _AddOnForm(
              onAdd: (addon) {
                _cubit.addAddon(addon);
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            if (_cubit.addOns.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'selected_addons'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _cubit.addOns
                        .map(
                          (addon) => Chip(
                            label: Text('${addon.name} ×${addon.quantity}'),
                            deleteIcon: const Icon(Icons.close),
                            onDeleted: () {
                              _cubit.removeAddon(addon.id);
                              setState(() {});
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'no_addons_selected'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.note_2,
                    color: AppColors.primaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'additional_notes'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _specialRequestController,
              decoration: InputDecoration(
                hintText: 'special_requirements_hint'.tr(),
              ),
              maxLines: 4,
              onChanged: (value) {
                _cubit.updateSpecialRequirements(value);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadSection(BuildContext context) {
    final hasFile = _cubit.participantsFileBytes != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.document_upload,
                    color: AppColors.primaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'upload_participants'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasFile)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'upload_participants_required'.tr(),
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            OutlinedButton.icon(
              onPressed: () async {
                final Uri url = Uri.parse(
                  '${ApiConstants.baseUrl}/trips/template/download',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('cannot_open_link'.tr())),
                    );
                  }
                }
              },
              icon: const Icon(Icons.download_for_offline_outlined),
              label: Text('download_template'.tr()),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _handleFileUpload,
              icon: Icon(
                hasFile ? Icons.check_circle_outline : Icons.upload_file,
              ),
              label: Text(
                hasFile
                    ? 'reupload_participants'.tr()
                    : 'upload_participants'.tr(),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 0),
                backgroundColor: hasFile ? Colors.green.shade50 : null,
                foregroundColor: hasFile ? Colors.green.shade700 : null,
              ),
            ),
            if (hasFile) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Text(
                  _cubit.participantsFileName ?? '',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleFileUpload() async {
    final pickResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (pickResult == null || pickResult.files.isEmpty) {
      return;
    }

    final file = pickResult.files.first;
    final bytes = file.bytes ?? await _readFileBytes(file);
    if (bytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('file_pick_failed'.tr())));
      return;
    }

    setState(() {
      _cubit.updateParticipantsFile(bytes, file.name);
    });
  }

  Future<Uint8List?> _readFileBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes;
    }
    final stream = file.readStream;
    if (stream == null) return null;
    final builder = BytesBuilder();
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    return builder.toBytes();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _cubit.submit();
    }
  }
}

class _AddOnForm extends StatefulWidget {
  const _AddOnForm({required this.onAdd});

  final ValueChanged<TripAddOnEntity> onAdd;

  @override
  State<_AddOnForm> createState() => _AddOnFormState();
}

class _AddOnFormState extends State<_AddOnForm> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'addon_name'.tr(),
                  prefixIcon: const Icon(Iconsax.category),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'price'.tr(),
                  prefixIcon: const Icon(Iconsax.card),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'quantity'.tr(),
                  prefixIcon: const Icon(Iconsax.ticket),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _addAddon,
              icon: const Icon(Icons.add),
              label: Text('add_addon'.tr()),
            ),
          ],
        ),
      ],
    );
  }

  void _addAddon() {
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('addon_input_invalid'.tr())));
      return;
    }

    widget.onAdd(
      TripAddOnEntity(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        price: price,
        quantity: quantity,
      ),
    );

    _nameController.clear();
    _priceController.clear();
    _quantityController.text = '1';
  }
}
