// Create Event Request Page - Step-based Wizard
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../auth/di/auth_injection.dart';
import '../../../branches/data/branches_api.dart';
import '../../../branches/data/branches_repository.dart';
import '../../../home/data/models/branch_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/event_time_slot_display.dart';
import '../cubit/event_request_cubit.dart';
import '../cubit/event_request_state.dart';
import 'event_request_details_page.dart';

const List<String> _kPrivateEventTimeSlots = [
  '16:00-18:00',
  '19:00-21:00',
  '22:00-00:00',
];

class CreateEventRequestPage extends StatelessWidget {
  final String? branchId;

  const CreateEventRequestPage({super.key, this.branchId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EventRequestCubit>(),
      child: _CreateEventRequestWizardBody(branchId: branchId),
    );
  }
}

class _CreateEventRequestWizardBody extends StatefulWidget {
  final String? branchId;

  const _CreateEventRequestWizardBody({this.branchId});

  @override
  State<_CreateEventRequestWizardBody> createState() =>
      _CreateEventRequestWizardBodyState();
}

class _CreateEventRequestWizardBodyState
    extends State<_CreateEventRequestWizardBody> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  late final EventRequestCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  String? _notes;
  List<BranchModel> _branches = [];
  bool _loadingBranches = true;
  bool _checkingQuotedRedirect = false;
  bool _didRedirectToPendingQuote = false;

  bool _configLoading = false;
  String? _configError;
  Map<String, dynamic> _eventConfig = {};
  final Map<String, int> _addonQtyById = {};

  bool _termsAccepted = false;
  String _paymentOption = 'full';
  bool _decorated = false;
  int _persons = 10;

  static const int _fixedDurationHours = 2;

  final List<String> _eventTypes = [
    'birthday',
    'graduation',
    'family',
    'other',
  ];

  // Local state
  String? _selectedType;
  String? _selectedBranchId;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<EventRequestCubit>();
    _loadBranches();
    if (widget.branchId != null) {
      _selectedBranchId = widget.branchId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bid = _selectedBranchId;
      if (bid != null && bid.isNotEmpty) {
        _tryRedirectQuotedPaymentIfAny(bid);
      }
    });
  }

  Future<void> _tryRedirectQuotedPaymentIfAny(String branchId) async {
    if (!mounted || branchId.isEmpty || _didRedirectToPendingQuote) return;
    setState(() => _checkingQuotedRedirect = true);
    try {
      final id = await _cubit.findQuotedRequestIdForBranch(branchId);
      if (!mounted || _didRedirectToPendingQuote) return;
      if (id != null && id.isNotEmpty) {
        _didRedirectToPendingQuote = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => EventRequestDetailsPage(requestId: id),
          ),
        );
        return;
      }
    } finally {
      if (mounted && !_didRedirectToPendingQuote) {
        setState(() => _checkingQuotedRedirect = false);
      }
    }
  }

  String _getEventTypeTranslation(String type) {
    switch (type) {
      case 'birthday':
        return 'event_type_birthday'.tr();
      case 'graduation':
        return 'event_type_graduation'.tr();
      case 'family':
        return 'event_type_family'.tr();
      case 'corporate':
        return 'event_type_corporate'.tr();
      case 'wedding':
        return 'event_type_wedding'.tr();
      case 'other':
        return 'event_type_other'.tr();
      default:
        return type;
    }
  }

  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'birthday':
        return const Color(0xFFEC4899);
      case 'graduation':
        return const Color(0xFF8B5CF6);
      case 'family':
        return const Color(0xFF06B6D4);
      case 'corporate':
        return const Color(0xFF3B82F6);
      case 'wedding':
        return const Color(0xFFF43F5E);
      default:
        return AppColors.primaryOrange;
    }
  }

  IconData _getEventTypeIcon(String type) {
    switch (type) {
      case 'birthday':
        return Iconsax.cake;
      case 'graduation':
        return Iconsax.medal_star;
      case 'family':
        return Iconsax.home_2;
      case 'corporate':
        return Iconsax.briefcase;
      case 'wedding':
        return Iconsax.heart;
      default:
        return Iconsax.star;
    }
  }

  int get _maxPersons {
    final v = _eventConfig['maxPersons'];
    if (v is int) return v.clamp(1, 100);
    if (v is num) return v.toInt().clamp(1, 100);
    return 15;
  }

  num get _baseHallPrice {
    final v = _eventConfig['baseHallRentalPrice'];
    if (v is num) return v;
    return 200;
  }

  num get _depositPercent {
    final v = _eventConfig['depositPercentage'];
    if (v is num) return v;
    return 20;
  }

  List<Map<String, dynamic>> get _addonCatalog {
    final raw = _eventConfig['addOns'];
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  List<String> get _availableSlotLabels {
    final raw = _eventConfig['timeSlots'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => e.toString()).toList();
    }
    return List<String>.from(_kPrivateEventTimeSlots);
  }

  List<String> get _bookedSlotLabels {
    final raw = _eventConfig['bookedTimeSlots'];
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).toList();
  }

  List<String> get _termsList {
    final raw = _eventConfig['terms'];
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).toList();
  }

  num _addonsSubtotal() {
    num sum = 0;
    for (final e in _addonCatalog) {
      final id = e['id']?.toString() ?? '';
      final qty = _addonQtyById[id] ?? 0;
      if (qty <= 0) continue;
      final price = e['price'] is num ? e['price'] : 0;
      sum += price * qty;
    }
    return sum;
  }

  num get _totalAmount => _baseHallPrice + _addonsSubtotal();

  double get _depositAmount =>
      (_totalAmount * _depositPercent / 100).toDouble();

  bool _slotSelectable(String slot) {
    if (_bookedSlotLabels.contains(slot)) return false;
    return _availableSlotLabels.contains(slot);
  }

  Future<void> _loadBranches() async {
    setState(() => _loadingBranches = true);
    try {
      final repo = BranchesRepositoryImpl(api: BranchesApi());
      final branchEntities = await repo.getAllBranches(includeInactive: false);
      if (!mounted) return;
      setState(() {
        _branches = branchEntities
            .map((e) => BranchModel.fromEntity(e))
            .toList();
        _loadingBranches = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingBranches = false);
    }
  }

  Future<void> _reloadEventConfig() async {
    final branchId = _selectedBranchId;
    if (branchId == null || branchId.isEmpty) return;

    setState(() {
      _configLoading = true;
      _configError = null;
    });

    try {
      final dateStr = _selectedDate != null
          ? '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
          : null;

      final map = await _cubit.loadEventConfig(
        branchId: branchId,
        date: dateStr,
      );

      if (!mounted) return;
      setState(() {
        _eventConfig = map;
        _configLoading = false;
        if (_selectedTimeSlot != null && !_slotSelectable(_selectedTimeSlot!)) {
          _selectedTimeSlot = null;
        }
        if (_persons > _maxPersons) {
          _persons = _maxPersons;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _configError = e.toString();
        _configLoading = false;
      });
    }
  }

  List<Map<String, dynamic>>? _buildAddOnsPayload() {
    final out = <Map<String, dynamic>>[];
    for (final item in _addonCatalog) {
      final id = item['id']?.toString() ?? '';
      final qty = _addonQtyById[id] ?? 0;
      if (qty <= 0) continue;
      out.add({
        'id': id,
        'name': item['name']?.toString() ?? '',
        'price': item['price'] is num ? item['price'] : 0,
        'quantity': qty,
      });
    }
    return out.isEmpty ? null : out;
  }

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0:
        return _selectedType != null &&
            _selectedType!.isNotEmpty &&
            _selectedBranchId != null &&
            _selectedBranchId!.isNotEmpty;
      case 1:
        return _selectedDate != null && _selectedTimeSlot != null;
      case 2:
        return _termsAccepted;
      case 3:
        return true;
      default:
        return false;
    }
  }

  bool get _isAllDataComplete {
    return _selectedType != null &&
        _selectedBranchId != null &&
        _selectedDate != null &&
        _selectedTimeSlot != null &&
        _termsAccepted;
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1 && _canProceedFromStep(_currentStep)) {
      final fromStep = _currentStep;
      setState(() => _currentStep++);

      if (fromStep == 0 && _currentStep == 1) {
        if (_selectedBranchId != null &&
            _availableSlotLabels.isEmpty &&
            !_configLoading) {
          _reloadEventConfig();
        }
      }
    } else {
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
        return 'event_type_branch'.tr();
      case 1:
        return 'schedule_details'.tr();
      case 2:
        return 'payment_addons'.tr();
      case 3:
        return 'review_submit'.tr();
      default:
        return '';
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isActive
                            ? AppColors.primaryRed
                            : const Color(0xFFF1F5F9),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryRed.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
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
                                      : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStepTitle(index),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? AppColors.primaryRed
                            : const Color(0xFF94A3B8),
                        fontFamily: 'MontserratArabic',
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
          const SizedBox(height: 16),
          Row(
            children: List.generate(_totalSteps - 1, (index) {
              final isCompleted = index < _currentStep;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primaryRed
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
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
        return _buildStep0EventTypeBranch();
      case 1:
        return _buildStep1ScheduleDetails();
      case 2:
        return _buildStep2PaymentAddons();
      case 3:
        return _buildStep3Summary();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<EventRequestCubit, EventRequestState>(
        listener: (context, state) {
          if (state is EventRequestCreated) {
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text('request_created_successfully'.tr())),
                  ],
                ),
                backgroundColor: AppColors.successColor,
              ),
            );
            if (_paymentOption == 'deposit') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => EventRequestDetailsPage(
                    requestId: state.request.id,
                    initialPayableAmount: _depositAmount,
                    initialGrandTotal: _totalAmount.toDouble(),
                    initialAddonsTotal: _addonsSubtotal().toDouble(),
                    initialPaymentOption: _paymentOption,
                    initialSelectedTimeSlot: _selectedTimeSlot,
                    initialDecorated: _decorated,
                    autoStartPayment: true,
                  ),
                ),
              );
              return;
            }
            Navigator.pop(context);
          } else if (state is EventRequestCreateError) {
            final redirectId = state.redirectToRequestId;
            if (redirectId != null && redirectId.isNotEmpty) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      EventRequestDetailsPage(requestId: redirectId),
                ),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Iconsax.warning_2, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
        },
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.arrow_left_2,
                      color: Color(0xFF1E293B),
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'create_special_booking_request'.tr(),
                  style: const TextStyle(
                    fontFamily: 'MontserratArabic',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                centerTitle: true,
              ),
              body: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProgressIndicator(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildStepContent(),
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: _buildBottomBar(),
            ),
            if (_checkingQuotedRedirect)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.25),
                  child: const Center(
                    child: Card(
                      elevation: 8,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [CircularProgressIndicator(strokeWidth: 2)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final canProceed = _canProceedFromStep(_currentStep);
    final isLastStep = _currentStep == _totalSteps - 1;
    final canSubmit = isLastStep ? _isAllDataComplete : canProceed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _previousStep();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.arrow_left_2,
                          size: 18,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'back'.tr(),
                          style: const TextStyle(
                            fontFamily: 'MontserratArabic',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: GestureDetector(
                onTap: canSubmit
                    ? () {
                        HapticFeedback.mediumImpact();
                        if (isLastStep) {
                          _submit();
                        } else {
                          _nextStep();
                        }
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: canSubmit
                        ? const LinearGradient(
                            colors: [
                              AppColors.primaryOrange,
                              AppColors.primaryRed,
                            ],
                          )
                        : null,
                    color: canSubmit ? null : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: canSubmit
                        ? [
                            BoxShadow(
                              color: AppColors.primaryRed.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastStep
                            ? 'submit_request'.tr()
                            : 'continue_step'.tr(),
                        style: TextStyle(
                          fontFamily: 'MontserratArabic',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: canSubmit
                              ? Colors.white
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLastStep ? Iconsax.send_1 : Iconsax.arrow_right_1,
                        size: 18,
                        color: canSubmit
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 0: Event Type & Branch
  Widget _buildStep0EventTypeBranch() {
    return Column(
      children: [
        _buildSectionCard(
          icon: Iconsax.star,
          iconColor: const Color(0xFFEC4899),
          title: 'event_type'.tr(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'please_select_event_type'.tr(),
                style: const TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _eventTypes.map((type) {
                  final isSelected = _selectedType == type;
                  final color = _getEventTypeColor(type);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedType = type);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getEventTypeIcon(type),
                            size: 18,
                            color: isSelected ? color : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getEventTypeTranslation(type),
                            style: TextStyle(
                              fontFamily: 'MontserratArabic',
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? color
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          icon: Iconsax.building_3,
          iconColor: AppColors.primaryRed,
          title: 'branch'.tr(),
          child: _loadingBranches
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedBranchId,
                  decoration: InputDecoration(
                    hintText: 'please_select_branch'.tr(),
                    hintStyle: const TextStyle(
                      fontFamily: 'MontserratArabic',
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  items: _branches.map((branch) {
                    return DropdownMenuItem(
                      value: branch.id,
                      child: Text(
                        branch.nameAr,
                        style: const TextStyle(
                          fontFamily: 'MontserratArabic',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    HapticFeedback.selectionClick();
                    if (value == null) return;
                    setState(() {
                      _selectedBranchId = value;
                      _selectedTimeSlot = null;
                    });
                    await _tryRedirectQuotedPaymentIfAny(value);
                    if (!mounted) return;
                    _reloadEventConfig();
                  },
                ),
        ),
      ],
    );
  }

  // Step 1: Schedule & Details
  Widget _buildStep1ScheduleDetails() {
    return Column(
      children: [
        _buildSectionCard(
          icon: Iconsax.calendar_1,
          iconColor: const Color(0xFF8B5CF6),
          title: 'preferred_date'.tr(),
          child: GestureDetector(
            onTap: () async {
              HapticFeedback.selectionClick();
              final now = DateTime.now();
              final tomorrow = DateTime(
                now.year,
                now.month,
                now.day,
              ).add(const Duration(days: 1));
              final picked = await showDatePicker(
                context: context,
                firstDate: tomorrow,
                lastDate: now.add(const Duration(days: 365)),
                initialDate: _selectedDate ?? tomorrow,
              );
              if (!mounted || picked == null) return;
              setState(() {
                _selectedDate = picked;
                _selectedTimeSlot = null;
              });
              _reloadEventConfig();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Iconsax.calendar_1,
                      size: 20,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? DateFormat.yMMMMd(
                              context.locale.toString(),
                            ).format(_selectedDate!)
                          : 'select_date'.tr(),
                      style: TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedDate != null
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Icon(
                    Iconsax.arrow_right_1,
                    size: 20,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          icon: Iconsax.clock,
          iconColor: const Color(0xFF06B6D4),
          title: 'select_slot'.tr(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_configLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_configError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.warning_2,
                        color: Colors.red.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _configError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_availableSlotLabels.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'select_date_first'.tr(),
                        style: const TextStyle(
                          fontFamily: 'MontserratArabic',
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableSlotLabels.map((slot) {
                    final selectable = _slotSelectable(slot);
                    final selected = _selectedTimeSlot == slot;

                    return GestureDetector(
                      onTap: selectable
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedTimeSlot = slot);
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryRed.withOpacity(0.1)
                              : selectable
                              ? Colors.white
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryRed
                                : const Color(0xFFE2E8F0),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.clock,
                              size: 16,
                              color: selected
                                  ? AppColors.primaryRed
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatEventTimeSlotRange12h(
                                slot,
                                context.locale.toString(),
                              ),
                              style: TextStyle(
                                fontFamily: 'MontserratArabic',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.primaryRed
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            if (!selectable) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Iconsax.close_circle,
                                size: 14,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (_selectedTimeSlot != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.timer,
                        size: 16,
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${'duration_hours'.tr()}: $_fixedDurationHours',
                        style: const TextStyle(
                          fontFamily: 'MontserratArabic',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          icon: Iconsax.people,
          iconColor: const Color(0xFF3B82F6),
          title: 'persons_count'.tr(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.people,
                    size: 20,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'event_max_persons_hint'.tr(
                          args: [_maxPersons.toString()],
                        ),
                        style: const TextStyle(
                          fontFamily: 'MontserratArabic',
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_persons',
                        style: const TextStyle(
                          fontFamily: 'MontserratArabic',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCounterButton(
                  icon: Iconsax.minus,
                  onTap: _persons > 1
                      ? () {
                          HapticFeedback.selectionClick();
                          setState(() => _persons--);
                        }
                      : null,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                _buildCounterButton(
                  icon: Iconsax.add,
                  onTap: _persons < _maxPersons
                      ? () {
                          HapticFeedback.selectionClick();
                          setState(() => _persons++);
                        }
                      : null,
                  color: const Color(0xFF3B82F6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          icon: Iconsax.magic_star,
          iconColor: AppColors.primaryPink,
          title: 'decoration'.tr(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.magic_star,
                    size: 20,
                    color: AppColors.primaryPink,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'decoration'.tr(),
                        style: const TextStyle(
                          fontFamily: 'MontserratArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
                Switch(
                  value: _decorated,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _decorated = v);
                  },
                  activeColor: AppColors.primaryPink,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Step 2: Payment & Add-ons
  Widget _buildStep2PaymentAddons() {
    return Column(
      children: [
        _buildSectionCard(
          icon: Iconsax.wallet_3,
          iconColor: AppColors.luxuryGold,
          title: 'select_payment_method'.tr(),
          child: Column(
            children: [
              _buildPaymentOption(
                value: 'full',
                title: 'trip_pay_full'.tr(),
                subtitle: 'pay_total_now'.tr(),
                icon: Iconsax.wallet_3,
                color: AppColors.successColor,
              ),
              Divider(height: 1, color: const Color(0xFFE2E8F0)),
              _buildPaymentOption(
                value: 'deposit',
                title: 'pay_deposit'.tr(args: [_depositPercent.toString()]),
                subtitle: 'pay_percentage_now'.tr(),
                icon: Iconsax.bank,
                color: AppColors.luxuryGold,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_addonCatalog.isNotEmpty)
          _buildSectionCard(
            icon: Iconsax.box,
            iconColor: const Color(0xFFEC4899),
            title: 'trip_addons'.tr(),
            child: Column(
              children: [
                ..._addonCatalog.map(_buildAddonRow),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'trip_addons_total'.tr(),
                        style: const TextStyle(
                          fontFamily: 'MontserratArabic',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      Text(
                        '${_addonsSubtotal().toStringAsFixed(2)} ${'currency'.tr()}',
                        style: TextStyle(
                          fontFamily: 'MontserratArabic',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (_addonCatalog.isNotEmpty) const SizedBox(height: 16),
        _buildSectionCard(
          icon: Iconsax.note_2,
          iconColor: const Color(0xFFF59E0B),
          title: 'additional_notes'.tr(),
          child: TextFormField(
            initialValue: _notes,
            decoration: InputDecoration(
              hintText: 'special_requirements_hint'.tr(),
              hintStyle: const TextStyle(
                fontFamily: 'MontserratArabic',
                color: Color(0xFF94A3B8),
              ),
            ),
            maxLines: 3,
            onChanged: (value) => _notes = value,
          ),
        ),
        const SizedBox(height: 16),
        if (_termsList.isNotEmpty)
          _buildSectionCard(
            icon: Iconsax.document,
            iconColor: AppColors.greyMedium,
            title: 'terms_and_conditions'.tr(),
            child: Column(
              children: [
                ..._termsList
                    .map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.successColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Iconsax.tick_circle,
                                size: 12,
                                color: AppColors.successColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontFamily: 'MontserratArabic',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF475569),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _termsAccepted = !_termsAccepted);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _termsAccepted
                          ? AppColors.successColor.withOpacity(0.08)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _termsAccepted
                            ? AppColors.successColor.withOpacity(0.3)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _termsAccepted
                                ? AppColors.successColor
                                : Colors.transparent,
                            border: Border.all(
                              color: _termsAccepted
                                  ? AppColors.successColor
                                  : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                          ),
                          child: _termsAccepted
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'accept_terms_conditions'.tr(),
                            style: TextStyle(
                              fontFamily: 'MontserratArabic',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _termsAccepted
                                  ? AppColors.successColor
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Step 3: Summary
  Widget _buildStep3Summary() {
    final addons = _addonsSubtotal();
    final total = _totalAmount;
    final dep = _depositAmount;
    final rem = total - dep;

    return Column(
      children: [
        _buildSectionCard(
          icon: Iconsax.star,
          iconColor: _selectedType != null
              ? _getEventTypeColor(_selectedType!)
              : AppColors.primaryOrange,
          title: 'event_info'.tr(),
          child: Column(
            children: [
              _buildSummaryRow(
                'event_type'.tr(),
                _selectedType != null
                    ? _getEventTypeTranslation(_selectedType!)
                    : '-',
                Iconsax.cake,
              ),
              _buildSummaryRow(
                'branch'.tr(),
                _branches
                        .where((b) => b.id == _selectedBranchId)
                        .map((b) => b.nameAr)
                        .firstOrNull ??
                    '-',
                Iconsax.building_3,
              ),
              _buildSummaryRow(
                'date_time'.tr(),
                _selectedDate != null && _selectedTimeSlot != null
                    ? '${DateFormat('yyyy/MM/dd').format(_selectedDate!)} · ${formatEventTimeSlotRange12h(_selectedTimeSlot!, context.locale.toString())}'
                    : '-',
                Iconsax.calendar_1,
              ),
              _buildSummaryRow(
                'duration'.tr(),
                '$_fixedDurationHours ${'hours'.tr()}',
                Iconsax.timer,
              ),
              _buildSummaryRow(
                'persons_count'.tr(),
                '$_persons ${'persons'.tr()}',
                Iconsax.people,
              ),
              if (_decorated)
                _buildSummaryRow(
                  'decoration'.tr(),
                  'yes'.tr(),
                  Iconsax.magic_star,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          icon: Iconsax.receipt,
          iconColor: AppColors.primaryOrange,
          title: 'price_summary'.tr(),
          headerColor: AppColors.primaryRed,
          child: Column(
            children: [
              _buildPriceRow('hall_rental'.tr(), _baseHallPrice),
              if (addons > 0) _buildPriceRow('trip_addons'.tr(), addons),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: AppColors.primaryOrange.withOpacity(0.1),
              ),
              const SizedBox(height: 12),
              _buildPriceRow('total'.tr(), total, isBold: true, isTotal: true),
              if (_paymentOption == 'deposit') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.luxuryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow(
                        'deposit_now'.tr(),
                        dep,
                        valueColor: AppColors.luxuryGold,
                      ),
                      const SizedBox(height: 6),
                      _buildPriceRow(
                        'remaining_later'.tr(),
                        rem,
                        valueColor: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_addonQtyById.isNotEmpty && _addonQtyById.values.any((v) => v > 0))
          _buildSectionCard(
            icon: Iconsax.box,
            iconColor: const Color(0xFFEC4899),
            title: 'selected_addons'.tr(),
            child: Column(
              children: _addonCatalog
                  .where(
                    (item) =>
                        (_addonQtyById[item['id']?.toString() ?? ''] ?? 0) > 0,
                  )
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Iconsax.add,
                              size: 14,
                              color: const Color(0xFFEC4899),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item['name']?.toString() ?? '',
                              style: const TextStyle(
                                fontFamily: 'MontserratArabic',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Text(
                            'x${_addonQtyById[item['id']?.toString() ?? '']}',
                            style: TextStyle(
                              fontFamily: 'MontserratArabic',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
    Color? headerColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: headerColor ?? iconColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (headerColor ?? iconColor).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: headerColor ?? iconColor),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'MontserratArabic',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: headerColor ?? const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final selected = _paymentOption == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _paymentOption = value);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(selected ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'MontserratArabic',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? color : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'MontserratArabic',
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                  color: selected ? color : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonRow(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final name = item['name']?.toString() ?? id;
    final price = item['price'] is num ? item['price'] : 0;
    final qty = _addonQtyById[id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: qty > 0
              ? AppColors.primaryOrange.withOpacity(0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'MontserratArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$price ${'currency'.tr()}',
                  style: TextStyle(
                    fontFamily: 'MontserratArabic',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildCounterButton(
                icon: Iconsax.minus,
                onTap: qty > 0
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (qty - 1 <= 0) {
                            _addonQtyById.remove(id);
                          } else {
                            _addonQtyById[id] = qty - 1;
                          }
                        });
                      }
                    : null,
                color: const Color(0xFFEC4899),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    fontFamily: 'MontserratArabic',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              _buildCounterButton(
                icon: Iconsax.add,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _addonQtyById[id] = qty + 1);
                },
                color: const Color(0xFFEC4899),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    VoidCallback? onTap,
    required Color color,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? color : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'MontserratArabic',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    num value, {
    bool isBold = false,
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: isTotal ? 15 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
          Row(
            children: [
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: isTotal ? 20 : 14,
                  fontWeight: FontWeight.w800,
                  color:
                      valueColor ??
                      (isBold ? AppColors.primaryRed : const Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'currency'.tr(),
                style: TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: (valueColor ?? const Color(0xFF94A3B8)).withOpacity(
                    0.7,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_isAllDataComplete) return;

    _cubit.createRequest(
      type: _selectedType!,
      branchId: _selectedBranchId!,
      hallId: null,
      startTime: _selectedDate!,
      durationHours: _fixedDurationHours,
      persons: _persons,
      decorated: _decorated,
      addOns: _buildAddOnsPayload(),
      notes: _notes?.isEmpty == true ? null : _notes,
      selectedTimeSlot: _selectedTimeSlot!,
      acceptedTerms: _termsAccepted,
      paymentOption: _paymentOption,
      paymentMethod: null,
    );
  }
}
