import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

import '../../di/trips_injection.dart' as trips_di;
import '../../domain/repositories/trips_repository.dart';
import '../../domain/entities/trip_addon_entity.dart';
import '../cubit/create_trip_request_cubit.dart';
import '../cubit/create_trip_request_state.dart';

int _durationHoursFromTripSlotLabel(String slot) {
  try {
    final parts = slot.split('-');
    if (parts.length != 2) return 2;
    final s = parts[0].trim().split(':');
    final e = parts[1].trim().split(':');
    final sh = int.parse(s[0]);
    final sm = int.parse(s.length > 1 ? s[1] : '0');
    final eh = int.parse(e[0]);
    final em = int.parse(e.length > 1 ? e[1] : '0');
    final minutes = eh * 60 + em - (sh * 60 + sm);
    final h = (minutes / 60).ceil();
    return h.clamp(1, 24);
  } catch (_) {
    return 2;
  }
}

class TripRequestWizardPage extends StatefulWidget {
  final String? branchId;

  const TripRequestWizardPage({super.key, this.branchId});

  @override
  State<TripRequestWizardPage> createState() => _TripRequestWizardPageState();
}

class _TripRequestWizardPageState extends State<TripRequestWizardPage>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps = 2;

  late final CreateTripRequestCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _specialRequestController = TextEditingController();
  final _studentsCountController = TextEditingController();

  List<Map<String, dynamic>> availableBranches = [];
  bool isLoadingBranches = false;
  String? branchesError;

  List<String> tripTimeSlots = [];
  String? selectedTripSlotLabel;
  bool tripConfigLoading = false;
  String? tripConfigError;
  Map<String, dynamic> tripConfig = {};
  final Map<String, int> tripAddonQtyById = {};

  late AnimationController _stepController;

  @override
  void initState() {
    super.initState();
    _cubit = trips_di.sl<CreateTripRequestCubit>();
    _studentsCountController.text = _cubit.studentsCount.toString();
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _stepController.forward();
    _loadBranches();

    if (widget.branchId != null) {
      _cubit.updateSelectedBranchId(widget.branchId!);
    }
  }

  @override
  void dispose() {
    _stepController.dispose();
    _cubit.close();
    _schoolNameController.dispose();
    _specialRequestController.dispose();
    _studentsCountController.dispose();
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

  Future<void> _fetchTripConfig() async {
    final branchId = _cubit.selectedBranchId;
    if (branchId == null || branchId.isEmpty) {
      setState(() {
        tripTimeSlots = [];
        tripConfigError = null;
        selectedTripSlotLabel = null;
      });
      return;
    }

    final d = _cubit.preferredDate;
    final dateStr =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    setState(() {
      tripConfigLoading = true;
      tripConfigError = null;
    });

    try {
      final repo = trips_di.sl<TripsRepository>();
      final cfg = await repo.getTripConfig(
        branchId: branchId,
        preferredDate: dateStr,
      );
      if (!mounted) return;
      _cubit.applyTripConfig(cfg);
      _studentsCountController.text = _cubit.studentsCount.toString();
      final slots = cfg['timeSlots'];
      final list = slots is List
          ? slots.map((e) => e.toString()).toList()
          : <String>[];
      setState(() {
        tripConfig = cfg;
        tripTimeSlots = list;
        tripConfigLoading = false;
        if (selectedTripSlotLabel != null &&
            !tripTimeSlots.contains(selectedTripSlotLabel)) {
          selectedTripSlotLabel = null;
          _cubit.updatePreferredTime(null);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        tripConfigLoading = false;
        tripConfigError = e.toString();
        tripTimeSlots = [];
      });
    }
  }

  void _onTripSlotSelected(String label) {
    HapticFeedback.selectionClick();
    setState(() {
      selectedTripSlotLabel = label;
    });
    _cubit.updatePreferredTime(label);
    _cubit.updateDurationHours(_durationHoursFromTripSlotLabel(label));
  }

  List<Map<String, dynamic>> get _tripAddonCatalog {
    final raw = tripConfig['addOns'];
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  void _bumpTripAddonQuantity(String id, int delta) {
    HapticFeedback.selectionClick();
    final cur = tripAddonQtyById[id] ?? 0;
    final next = (cur + delta).clamp(0, 99);
    setState(() {
      if (next <= 0) {
        tripAddonQtyById.remove(id);
      } else {
        tripAddonQtyById[id] = next;
      }
    });
    _syncTripAddonsFromUi();
  }

  void _syncTripAddonsFromUi() {
    for (final item in _tripAddonCatalog) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      _cubit.removeAddon(id);
    }
    for (final item in _tripAddonCatalog) {
      final id = item['id']?.toString() ?? '';
      final qty = tripAddonQtyById[id] ?? 0;
      if (qty <= 0 || id.isEmpty) continue;
      final name = item['name']?.toString() ?? '';
      final priceVal = item['price'];
      final price = priceVal is int
          ? priceVal
          : (priceVal is num
                ? priceVal.toInt()
                : int.tryParse(priceVal?.toString() ?? '0') ?? 0);
      _cubit.addAddon(
        TripAddOnEntity(id: id, name: name, price: price, quantity: qty),
      );
    }
  }

  double _addonsTotal() {
    double total = 0;
    for (final item in _tripAddonCatalog) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final qty = tripAddonQtyById[id] ?? 0;
      if (qty <= 0) continue;
      final priceVal = item['price'];
      final price = priceVal is num
          ? priceVal.toDouble()
          : double.tryParse(priceVal?.toString() ?? '0') ?? 0;
      total += price * qty;
    }
    return total;
  }

  double _ticketsTotal() {
    return _cubit.studentsCount * _cubit.ticketPricePerStudent;
  }

  double _grandTotal() {
    return _ticketsTotal() + _addonsTotal();
  }

  double _depositAmount() {
    return _grandTotal() * (_cubit.depositPercent / 100);
  }

  String _money(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0:
        return _cubit.schoolName.isNotEmpty &&
            _cubit.selectedBranchId != null &&
            _cubit.selectedBranchId!.isNotEmpty &&
            selectedTripSlotLabel != null &&
            _cubit.studentsCount >= _cubit.minimumStudentsForCreate;
      case 1:
        return true;
      default:
        return false;
    }
  }

  bool _isAllDataComplete() {
    return _cubit.schoolName.isNotEmpty &&
        _cubit.selectedBranchId != null &&
        _cubit.selectedBranchId!.isNotEmpty &&
        selectedTripSlotLabel != null &&
        _cubit.studentsCount >= _cubit.minimumStudentsForCreate &&
        !tripConfigLoading;
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1 && _canProceedFromStep(_currentStep)) {
      HapticFeedback.mediumImpact();
      setState(() => _currentStep++);
      _stepController.reset();
      _stepController.forward();
      if (_currentStep == 1) {
        if (_cubit.selectedBranchId != null &&
            _cubit.selectedBranchId!.isNotEmpty &&
            tripTimeSlots.isEmpty &&
            !tripConfigLoading) {
          _fetchTripConfig();
        }
      }
    } else {
      setState(() {});
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
      _stepController.reset();
      _stepController.forward();
    }
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'trip_details'.tr();
      case 1:
        return 'trip_summary'.tr();
      default:
        return '';
    }
  }

  IconData _getStepIcon(int step) {
    switch (step) {
      case 0:
        return Iconsax.edit;
      case 1:
        return Iconsax.document_text;
      default:
        return Iconsax.arrow_right;
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuart,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.primaryGradient : null,
                color: isCompleted
                    ? const Color(0xFFF8FAFC)
                    : (isActive ? null : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
                border: isCompleted
                    ? Border.all(color: const Color(0xFFE2E8F0), width: 1)
                    : Border.all(color: Colors.transparent, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.25)
                          : (isCompleted
                              ? AppColors.successColor.withValues(alpha: 0.1)
                              : const Color(0xFFF1F5F9)),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Iconsax.tick_circle, color: AppColors.successColor, size: 14)
                          : Icon(
                              _getStepIcon(index),
                              size: 14,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _getStepTitle(index),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : (isCompleted
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF94A3B8)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: child,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutQuart).slideY(
      begin: 0.1,
      duration: 400.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildStepContent() {
    return AnimatedBuilder(
      animation: _stepController,
      builder: (context, _) {
        final slideOffset =
            Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _stepController,
                curve: Curves.easeOutQuart,
              ),
            );
        final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _stepController, curve: Curves.easeOutQuart),
        );

        return SlideTransition(
          position: slideOffset,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: _buildCurrentStep(),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            _buildStep0SchoolInfo(),
            const SizedBox(height: 16),
            _buildStep1BranchHall(),
            const SizedBox(height: 16),
            _buildScheduleSection(context),
            const SizedBox(height: 16),
            _buildAddOnsSection(context),
            const SizedBox(height: 16),
            _buildTripPaymentSection(context),
            const SizedBox(height: 16),
            _buildNotesSection(context),
          ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05),
        );
      case 1:
        return _buildTripSummary();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
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
        ],
        child: BlocBuilder<CreateTripRequestCubit, CreateTripRequestState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
                title: Text(
                  'create_trip_request'.tr(),
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
                centerTitle: true,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(0),
                  child: Container(height: 1, color: const Color(0xFFF1F5F9)),
                ),
              ),
              body: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primaryRed,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.errorColor),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.errorColor,
                        width: 2,
                      ),
                    ),
                    prefixIconColor: const Color(0xFF94A3B8),
                    labelStyle: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    hintStyle: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                child: Form(
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

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: Text(
                    'previous'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuart,
                decoration: BoxDecoration(
                  gradient: canSubmit && !isSubmitting
                      ? AppColors.primaryGradient
                      : null,
                  color: canSubmit && !isSubmitting
                      ? null
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: canSubmit && !isSubmitting
                      ? (isLastStep ? _submit : _nextStep)
                      : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Text(
                                isLastStep
                                    ? 'confirm_and_submit'.tr()
                                    : 'review_request'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!isLastStep) ...[
                              const SizedBox(width: 6),
                              const Icon(Iconsax.arrow_right_3, size: 16),
                            ],
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

  Widget _buildStep0SchoolInfo() {
    return _buildSectionCard(
      icon: Iconsax.teacher,
      title: 'school_details'.tr(),
      accentColor: AppColors.primaryOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'enter_school_name_hint'.tr(),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _schoolNameController,
            decoration: InputDecoration(
              labelText: 'school_name'.tr(),
              prefixIcon: const Icon(Iconsax.teacher),
            ),
            onChanged: (value) {
              _cubit.updateSchoolName(value);
              setState(() {});
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'provide_school_name'.tr();
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep1BranchHall() {
    return _buildSectionCard(
      icon: Iconsax.building,
      title: 'branch_selection'.tr(),
      accentColor: AppColors.primaryRed,
      child: isLoadingBranches
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          : branchesError != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.errorColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.warning_2,
                    color: AppColors.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      branchesError!,
                      style: TextStyle(
                        color: AppColors.errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : DropdownButtonFormField<String>(
              initialValue: _cubit.selectedBranchId,
              decoration: InputDecoration(
                labelText: 'select_branch'.tr(),
                prefixIcon: const Icon(Iconsax.building),
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
                HapticFeedback.selectionClick();
                _cubit.updateSelectedBranchId(value);
                if (value != null && value.isNotEmpty) {
                  setState(() {
                    selectedTripSlotLabel = null;
                    _cubit.updatePreferredTime(null);
                  });
                  _fetchTripConfig();
                } else {
                  setState(() {
                    tripTimeSlots = [];
                    selectedTripSlotLabel = null;
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
    );
  }

  Widget _buildScheduleSection(BuildContext context) {
    final formattedDate = DateFormat.yMMMMd(
      context.locale.toString(),
    ).format(_cubit.preferredDate);

    return _buildSectionCard(
      icon: Iconsax.calendar_1,
      title: 'trip_schedule'.tr(),
      accentColor: AppColors.primaryOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDatePicker(context, formattedDate),
          const SizedBox(height: 16),
          if (tripConfigLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (tripConfigError != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.errorColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.warning_2,
                    color: AppColors.errorColor,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tripConfigError!,
                      style: TextStyle(
                        color: AppColors.errorColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (tripTimeSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.luxuryGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.luxuryGold.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.info_circle,
                    color: AppColors.luxuryGold,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'no_slots_available_for_date'.tr(),
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'booking_step_date_time'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tripTimeSlots.map((label) {
                final selected = selectedTripSlotLabel == label;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutQuart,
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.primaryGradient : null,
                    color: !selected ? Colors.white : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryRed
                          : const Color(0xFFE2E8F0),
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryRed.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _onTripSlotSelected(label),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF475569),
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_cubit.durationHours != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.clock,
                      size: 14,
                      color: AppColors.primaryOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${'duration_hours'.tr()}: ${_cubit.durationHours}',
                      style: const TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 16),
            Text(
              'students_count'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _studentsCountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'students_count'.tr(),
                prefixIcon: const Icon(Iconsax.profile_2user),
                helperText: tr(
                  'trip_min_students_note',
                  args: [_cubit.minimumStudentsForCreate.toString()],
                ),
                helperStyle: const TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                helperMaxLines: 3,
                errorMaxLines: 3,
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 0;
                _cubit.updateStudentsCount(parsed);
                setState(() {});
              },
              validator: (val) {
                final parsed = int.tryParse(val ?? '') ?? 0;
                if (parsed < _cubit.minimumStudentsForCreate) {
                  return tr(
                    'trip_min_students_error',
                    args: [_cubit.minimumStudentsForCreate.toString()],
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryRed.withValues(alpha: 0.06),
                    AppColors.primaryOrange.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryRed.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr(
                            'trip_price_per_student_value',
                            args: [_money(_cubit.ticketPricePerStudent)],
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(
                      'trip_tickets_total_value',
                      args: [_money(_ticketsTotal())],
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryRed,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String formattedDate) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primaryRed,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF1E293B),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            HapticFeedback.selectionClick();
            _cubit.updatePreferredDate(picked);
            setState(() {
              selectedTripSlotLabel = null;
              _cubit.updatePreferredTime(null);
            });
            if (_cubit.selectedBranchId != null &&
                _cubit.selectedBranchId!.isNotEmpty) {
              _fetchTripConfig();
            } else {
              setState(() {
                tripTimeSlots = [];
              });
            }
            setState(() {});
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.calendar_1,
                  color: AppColors.primaryOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'preferred_date'.tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Iconsax.arrow_down_1,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripPaymentSection(BuildContext context) {
    return _buildSectionCard(
      icon: Iconsax.wallet,
      title: 'trip_payment_option'.tr(),
      accentColor: AppColors.luxuryGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentOption(
            value: 'full',
            label: 'trip_pay_full'.tr(),
            subtitle: tr(
              'trip_grand_total_value',
              args: [_money(_grandTotal())],
            ),
            icon: Iconsax.wallet_check,
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            value: 'deposit',
            label: 'trip_pay_deposit'.tr(),
            subtitle: tr(
              'trip_deposit_amount_value',
              args: [_money(_cubit.depositPercent), _money(_depositAmount())],
            ),
            icon: Iconsax.wallet_money,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String label,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _cubit.paymentOption == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _cubit.updatePaymentOption(value);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutQuart,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryRed.withValues(alpha: 0.04)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: !isSelected ? const Color(0xFFE2E8F0) : null,
                border: !isSelected
                    ? Border.all(color: const Color(0xFFCBD5E1), width: 2)
                    : null,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryRed.withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primaryRed
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.primaryRed
                          : const Color(0xFF94A3B8),
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

  Widget _buildAddOnsSection(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = _tripAddonCatalog;

    return _buildSectionCard(
      icon: Iconsax.category,
      title: 'trip_addons'.tr(),
      accentColor: AppColors.luxuryGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'trip_addons_hint'.tr(),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          if (catalog.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.info_circle,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'no_addons_selected'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...catalog.map((item) {
              final id = item['id']?.toString() ?? '';
              final name = item['name']?.toString() ?? id;
              final priceVal = item['price'];
              final price = priceVal is int
                  ? priceVal
                  : (priceVal is num
                        ? priceVal.toInt()
                        : int.tryParse(priceVal?.toString() ?? '0') ?? 0);
              final qty = tripAddonQtyById[id] ?? 0;
              final itemTotal = price * qty;
              final description = item['description']?.toString();
              final hasQty = qty > 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutQuart,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: hasQty
                        ? AppColors.luxuryGold.withValues(alpha: 0.04)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasQty
                          ? AppColors.luxuryGold.withValues(alpha: 0.3)
                          : const Color(0xFFF1F5F9),
                      width: hasQty ? 1.5 : 1,
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
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: hasQty
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: hasQty
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '$price ${'riyal'.tr()}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (description != null && description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            if (hasQty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  tr(
                                    'trip_item_total_value',
                                    args: [_money(itemTotal.toDouble())],
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.luxuryGold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildQuantityButton(
                            icon: Iconsax.minus,
                            onPressed: qty <= 0
                                ? null
                                : () => _bumpTripAddonQuantity(id, -1),
                            isActive: qty > 0,
                          ),
                          Container(
                            width: 36,
                            alignment: Alignment.center,
                            child: Text(
                              '$qty',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: hasQty
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          _buildQuantityButton(
                            icon: Iconsax.add,
                            onPressed: id.isEmpty
                                ? null
                                : () => _bumpTripAddonQuantity(id, 1),
                            isActive: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (catalog.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.luxuryGold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.calculator,
                    size: 14,
                    color: AppColors.luxuryGold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'trip_addons_total'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_money(_addonsTotal())} ${'riyal'.tr()}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.luxuryGold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isActive,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryRed.withValues(alpha: 0.1)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        color: isActive ? AppColors.primaryRed : const Color(0xFFCBD5E1),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return _buildSectionCard(
      icon: Iconsax.note_2,
      title: 'additional_notes'.tr(),
      accentColor: const Color(0xFF64748B),
      child: TextFormField(
        controller: _specialRequestController,
        decoration: InputDecoration(
          hintText: 'special_requirements_hint'.tr(),
          alignLabelWithHint: true,
        ),
        maxLines: null,
        minLines: 3,
        onChanged: (value) {
          _cubit.updateSpecialRequirements(value);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildTripSummary() {
    final ticketsTotal = _ticketsTotal();
    final addonsTotal = _addonsTotal();
    final grandTotal = ticketsTotal + addonsTotal;
    final depositAmount = _depositAmount();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Iconsax.document_text5,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'trip_summary'.tr(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'review_your_trip_details'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_cubit.schoolName.isNotEmpty)
                  _buildSummaryItem(
                    icon: Iconsax.teacher,
                    label: 'school_name'.tr(),
                    value: _cubit.schoolName,
                  ),
                _buildSummaryItem(
                  icon: Iconsax.profile_2user,
                  label: 'students_count'.tr(),
                  value: '${_cubit.studentsCount} ${'persons'.tr()}',
                ),
                if (_cubit.selectedBranchId != null)
                  _buildSummaryItem(
                    icon: Iconsax.building,
                    label: 'branch'.tr(),
                    value: _getBranchName(_cubit.selectedBranchId!),
                  ),
                if (selectedTripSlotLabel != null)
                  _buildSummaryItem(
                    icon: Iconsax.calendar_1,
                    label: 'date_time'.tr(),
                    value:
                        '${DateFormat('yyyy/MM/dd').format(_cubit.preferredDate)} · $selectedTripSlotLabel',
                  ),
                if (_cubit.durationHours != null)
                  _buildSummaryItem(
                    icon: Iconsax.clock,
                    label: 'duration'.tr(),
                    value: '${_cubit.durationHours} ${'hours'.tr()}',
                  ),
                if (_cubit.addOns.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 12),
                      Text(
                        'selected_addons'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._cubit.addOns.map(
                        (addon) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.luxuryGold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${addon.name} ×${addon.quantity}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_cubit.specialRequirements != null &&
                    _cubit.specialRequirements!.isNotEmpty)
                  _buildSummaryItem(
                    icon: Iconsax.note_21,
                    label: 'additional_notes'.tr(),
                    value: _cubit.specialRequirements!,
                  ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'trip_price_per_student'.tr(),
                  '${_money(_cubit.ticketPricePerStudent)} ${'riyal'.tr()}',
                ),
                _buildSummaryRow(
                  'trip_tickets_total'.tr(),
                  '${_money(ticketsTotal)} ${'riyal'.tr()}',
                ),
                if (addonsTotal > 0)
                  _buildSummaryRow(
                    'trip_addons_total'.tr(),
                    '${_money(addonsTotal)} ${'riyal'.tr()}',
                  ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryRed.withValues(alpha: 0.08),
                        AppColors.primaryOrange.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryRed.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'trip_grand_total'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${_money(grandTotal)} ${'riyal'.tr()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryRed,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_cubit.paymentOption == 'deposit')
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.luxuryGold.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.luxuryGold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.wallet_money,
                          size: 16,
                          color: AppColors.luxuryGold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr(
                              'trip_deposit_with_percent',
                              args: [_money(_cubit.depositPercent)],
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.luxuryGold,
                            ),
                          ),
                        ),
                        Text(
                          '${_money(depositAmount)} ${'riyal'.tr()}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.luxuryGold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
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

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _syncTripAddonsFromUi();
      _cubit.submit();
    }
  }
}
