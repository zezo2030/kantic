import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class _TripRequestWizardPageState extends State<TripRequestWizardPage> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  late final CreateTripRequestCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _specialRequestController = TextEditingController();
  final _studentsCountController = TextEditingController();

  // Branch selection state
  List<Map<String, dynamic>> availableBranches = [];
  bool isLoadingBranches = false;
  String? branchesError;

  // School trip slots from GET /trips/config
  List<String> tripTimeSlots = [];
  String? selectedTripSlotLabel;
  bool tripConfigLoading = false;
  String? tripConfigError;
  Map<String, dynamic> tripConfig = {};
  final Map<String, int> tripAddonQtyById = {};

  @override
  void initState() {
    super.initState();
    _cubit = trips_di.sl<CreateTripRequestCubit>();
    _studentsCountController.text = _cubit.studentsCount.toString();
    _loadBranches(); // Load available branches

    if (widget.branchId != null) {
      _cubit.updateSelectedBranchId(widget.branchId!);
    }
  }

  @override
  void dispose() {
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

  String _money(double value) => value.toStringAsFixed(2);

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0: // School info & Branch
        return _cubit.schoolName.isNotEmpty &&
            _cubit.selectedBranchId != null &&
            _cubit.selectedBranchId!.isNotEmpty;
      case 1: // Schedule & Addons
        return selectedTripSlotLabel != null && 
               _cubit.studentsCount >= _cubit.minimumStudentsForCreate;
      case 2: // Payment & Notes
        return _cubit.paymentOption.isNotEmpty;
      case 3: // Summary
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
      final fromStep = _currentStep;
      setState(() => _currentStep++);

      if (fromStep == 0 && _currentStep == 1) {
        if (_cubit.selectedBranchId != null &&
            _cubit.selectedBranchId!.isNotEmpty &&
            tripTimeSlots.isEmpty &&
            !tripConfigLoading) {
          _fetchTripConfig();
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
        return 'trip_schedule'.tr();
      case 2:
        return 'trip_payment_option'.tr();
      case 3:
        return 'trip_summary'.tr();
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
        return Column(
          children: [
            _buildStep0SchoolInfo(),
            const SizedBox(height: 16),
            _buildStep1BranchHall(),
          ],
        );
      case 1:
        return Column(
          children: [
            _buildScheduleSection(context),
            const SizedBox(height: 16),
            _buildAddOnsSection(context),
          ],
        );
      case 2:
        return Column(
          children: [
            _buildTripPaymentSection(context),
            const SizedBox(height: 16),
            _buildNotesSection(context),
          ],
        );
      case 3:
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
    return _buildBranchHallSection();
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

            const SizedBox(height: 16),
          ],
        ),
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

            _buildSummaryRow(
              'students_count'.tr(),
              '${_cubit.studentsCount} ${'persons'.tr()}',
            ),

            // Branch
            if (_cubit.selectedBranchId != null)
              _buildSummaryRow(
                'branch'.tr(),
                _getBranchName(_cubit.selectedBranchId!),
              ),

            // Date and Time
            if (selectedTripSlotLabel != null)
              _buildSummaryRow(
                'date_time'.tr(),
                '${DateFormat('yyyy/MM/dd').format(_cubit.preferredDate)} · $selectedTripSlotLabel',
              ),

            // Duration
            if (_cubit.durationHours != null)
              _buildSummaryRow(
                'duration'.tr(),
                '${_cubit.durationHours} ${'hours'.tr()}',
              ),

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

            const Divider(height: 28),
            _buildSummaryRow(
              'trip_price_per_student'.tr(),
              '${_money(_cubit.ticketPricePerStudent)} ${'riyal'.tr()}',
            ),
            _buildSummaryRow(
              'trip_tickets_total'.tr(),
              '${_money(ticketsTotal)} ${'riyal'.tr()}',
            ),
            _buildSummaryRow(
              'trip_addons_total'.tr(),
              '${_money(addonsTotal)} ${'riyal'.tr()}',
            ),
            _buildSummaryRow(
              'trip_grand_total'.tr(),
              '${_money(grandTotal)} ${'riyal'.tr()}',
            ),
            if (_cubit.paymentOption == 'deposit')
              _buildSummaryRow(
                tr(
                  'trip_deposit_with_percent',
                  args: [_money(_cubit.depositPercent)],
                ),
                '${_money(depositAmount)} ${'riyal'.tr()}',
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
            ),
            const SizedBox(height: 8),
            if (tripConfigLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (tripConfigError != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  tripConfigError!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              )
            else if (tripTimeSlots.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'no_slots_available_for_date'.tr(),
                  style: TextStyle(color: Colors.orange.shade800),
                ),
              )
            else ...[
              Text(
                'booking_step_date_time'.tr(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tripTimeSlots.map((label) {
                  final selected = selectedTripSlotLabel == label;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => _onTripSlotSelected(label),
                  );
                }).toList(),
              ),
              if (_cubit.durationHours != null) ...[
                const SizedBox(height: 12),
                Text(
                  '${'duration_hours'.tr()}: ${_cubit.durationHours}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'students_count'.tr(),
                style: Theme.of(context).textTheme.titleSmall,
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
                  helperStyle: const TextStyle(color: AppColors.primaryRed),
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
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryRed.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(
                        'trip_price_per_student_value',
                        args: [_money(_cubit.ticketPricePerStudent)],
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(
                        'trip_tickets_total_value',
                        args: [_money(_ticketsTotal())],
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripPaymentSection(BuildContext context) {
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
            Text(
              'trip_payment_option'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            RadioListTile<String>(
              title: Text('trip_pay_full'.tr()),
              value: 'full',
              groupValue: _cubit.paymentOption,
              onChanged: (v) {
                _cubit.updatePaymentOption(v ?? 'full');
                setState(() {});
              },
            ),
            RadioListTile<String>(
              title: Text('trip_pay_deposit'.tr()),
              value: 'deposit',
              groupValue: _cubit.paymentOption,
              onChanged: (v) {
                _cubit.updatePaymentOption(v ?? 'deposit');
                setState(() {});
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                tr(
                  'trip_deposit_amount_value',
                  args: [_money(_cubit.depositPercent), _money(_depositAmount())],
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w600,
                ),
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
            if (catalog.isEmpty)
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
                return ListTile(
                  dense: true,
                  title: Text('$name ($price ${'riyal'.tr()})'),
                  subtitle: (qty > 0 ||
                          (description != null && description.isNotEmpty))
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (description != null && description.isNotEmpty)
                              Text(description),
                            if (qty > 0)
                              Text(
                                tr(
                                  'trip_item_total_value',
                                  args: [_money(itemTotal.toDouble())],
                                ),
                              ),
                          ],
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: qty <= 0
                            ? null
                            : () => _bumpTripAddonQuantity(id, -1),
                      ),
                      Text('$qty'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: id.isEmpty
                            ? null
                            : () => _bumpTripAddonQuantity(id, 1),
                      ),
                    ],
                  ),
                );
              }),
            if (catalog.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  tr(
                    'trip_addons_total_value',
                    args: [_money(_addonsTotal())],
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _syncTripAddonsFromUi();
      _cubit.submit();
    }
  }
}
