// Create Event Request Page - Presentation Layer
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../cubit/event_request_cubit.dart';
import '../cubit/event_request_state.dart';
import '../../../branches/data/branches_api.dart';
import '../../../branches/data/branches_repository.dart';
import '../../../home/data/models/branch_model.dart';
import '../../../auth/di/auth_injection.dart';
import '../../../booking/presentation/cubit/booking_cubit.dart';
import '../../../booking/presentation/cubit/booking_state.dart';
import '../../../booking/presentation/widgets/slot_selector.dart';
import '../../../booking/presentation/widgets/date_time_selector.dart';
import '../../../booking/domain/entities/time_slot_entity.dart';

class CreateEventRequestPage extends StatefulWidget {
  final String? branchId;

  const CreateEventRequestPage({super.key, this.branchId});

  @override
  State<CreateEventRequestPage> createState() => _CreateEventRequestPageState();
}

class _CreateEventRequestPageState extends State<CreateEventRequestPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  String? _selectedBranchId;
  String? _selectedHallId;
  DateTime? _selectedDate;
  TimeSlotEntity? _selectedSlot;
  int _durationHours = 2;

  // Slots state
  bool _isLoadingSlots = false;
  String? _slotsError;
  int _slotMinutes = 60;
  List<TimeSlotEntity> _availableSlots = [];
  int? _maxDurationForSlot;
  int _persons = 10;
  bool _decorated = false;
  String? _notes;
  List<BranchModel> _branches = [];
  bool _loadingBranches = true;

  final List<String> _eventTypes = [
    'birthday',
    'graduation',
    'family',
    'corporate',
    'wedding',
    'other',
  ];

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

  @override
  void initState() {
    super.initState();
    _loadBranches();
    // If branchId is provided, set it
    if (widget.branchId != null) {
      _selectedBranchId = widget.branchId;
    }
  }

  Future<void> _loadBranches() async {
    setState(() => _loadingBranches = true);
    try {
      final repo = BranchesRepositoryImpl(api: BranchesApi());
      final branchEntities = await repo.getAllBranches(includeInactive: false);
      setState(() {
        _branches = branchEntities
            .map((e) => BranchModel.fromEntity(e))
            .toList();
        _loadingBranches = false;
      });
    } catch (e) {
      setState(() => _loadingBranches = false);
    }
  }


  void _selectDate(DateTime date, BuildContext? cubitContext) {
    setState(() {
      _selectedDate = date;
      _selectedSlot = null;
    });
    if (cubitContext != null) {
      _fetchSlotsForDate(cubitContext);
    }
  }

  void _fetchSlotsForDate(BuildContext cubitContext) {
    final date = _selectedDate;
    final branchId = _selectedBranchId;

    if (date == null || branchId == null) {
      setState(() {
        _availableSlots = [];
        _slotsError = null;
        _maxDurationForSlot = null;
        _selectedSlot = null;
      });
      return;
    }

    final normalizedDate = DateTime(date.year, date.month, date.day);
    cubitContext.read<BookingCubit>().fetchBranchSlots(
      branchId: branchId,
      date: normalizedDate,
      durationHours: _durationHours,
      persons: _persons,
    );
  }

  void _onSlotSelected(TimeSlotEntity slot) {
    setState(() {
      _selectedSlot = slot;
      _selectedDate = DateTime(
        slot.start.year,
        slot.start.month,
        slot.start.day,
      );
    });
    _computeMaxDurationFromSlots();
  }

  void _computeMaxDurationFromSlots() {
    final slot = _selectedSlot;
    if (slot == null) {
      setState(() {
        _maxDurationForSlot = null;
      });
      return;
    }

    var maxHours = (slot.consecutiveSlots * _slotMinutes) ~/ 60;
    if (maxHours == 0 && slot.consecutiveSlots > 0) {
      maxHours = 1;
    }

    setState(() {
      _maxDurationForSlot = maxHours > 0 ? maxHours : 0;
    });

    if (_maxDurationForSlot != null &&
        _maxDurationForSlot! > 0 &&
        _durationHours > _maxDurationForSlot!) {
      setState(() {
        _durationHours = _maxDurationForSlot!;
      });
    }
  }

  void _submit(BuildContext cubitContext) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedSlot == null) {
      ScaffoldMessenger.of(cubitContext).showSnackBar(
        SnackBar(content: Text('please_select_date_time'.tr())),
      );
      return;
    }
    if (_selectedBranchId == null) {
      ScaffoldMessenger.of(
        cubitContext,
      ).showSnackBar(SnackBar(content: Text('please_select_branch'.tr())));
      return;
    }

    final startTime = _selectedSlot!.start;

    cubitContext.read<EventRequestCubit>().createRequest(
      type: _selectedType!,
      branchId: _selectedBranchId!,
      hallId: _selectedHallId,
      startTime: startTime,
      durationHours: _durationHours,
      persons: _persons,
      decorated: _decorated,
      notes: _notes?.isEmpty == true ? null : _notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<BookingCubit>()),
        BlocProvider(create: (_) => sl<EventRequestCubit>()),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text('create_special_booking_request'.tr())),
        body: BlocListener<BookingCubit, BookingState>(
          listener: (context, state) {
            if (state is SlotsLoading) {
              setState(() {
                _isLoadingSlots = true;
                _slotsError = null;
              });
            } else if (state is SlotsLoaded) {
              setState(() {
                _isLoadingSlots = false;
                _slotsError = null;
                _slotMinutes = state.branchSlots.slotMinutes;
                _availableSlots = state.branchSlots.slots;
              });

              // Auto-select first available slot if none selected
              if (_selectedSlot == null && _availableSlots.isNotEmpty) {
                final availableSlots = _availableSlots
                    .where((slot) => slot.available)
                    .toList();
                if (availableSlots.isNotEmpty) {
                  _onSlotSelected(availableSlots.first);
                }
              } else if (_selectedSlot != null) {
                // Re-select slot if still available
                final matchingSlot = _availableSlots
                    .where(
                      (slot) =>
                          slot.start.isAtSameMomentAs(_selectedSlot!.start) &&
                          slot.available,
                    )
                    .firstOrNull;
                if (matchingSlot != null) {
                  _onSlotSelected(matchingSlot);
                } else {
                  setState(() {
                    _selectedSlot = null;
                  });
                }
              }
            } else if (state is SlotsError) {
              setState(() {
                _isLoadingSlots = false;
                _slotsError = state.message;
                _availableSlots = [];
                _maxDurationForSlot = null;
              });
            }
          },
          child: BlocListener<EventRequestCubit, EventRequestState>(
            listener: (context, state) {
              if (state is EventRequestCreated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('request_created_successfully'.tr())),
                );
                Navigator.pop(context);
              } else if (state is EventRequestCreateError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            child: Builder(
              builder: (builderContext) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'event_type'.tr()),
                        initialValue: _selectedType,
                        items: _eventTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getEventTypeTranslation(type)),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedType = value),
                        validator: (value) =>
                            value == null ? 'please_select_event_type'.tr() : null,
                      ),
                      const SizedBox(height: 16),

                      // Branch
                      _loadingBranches
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'branch'.tr(),
                              ),
                              initialValue: _selectedBranchId,
                              items: _branches.map((branch) {
                                return DropdownMenuItem(
                                  value: branch.id,
                                  child: Text(branch.nameAr),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedBranchId = value;
                                  _selectedHallId = null;
                                  _selectedSlot = null;
                                  _selectedDate = null;
                                  _availableSlots = [];
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'please_select_branch'.tr() : null,
                            ),
                      const SizedBox(height: 16),

                      // Date Selector
                      DateTimeSelector(
                        selectedDate: _selectedDate,
                        selectedTime: null,
                        onDateChanged: (date) =>
                            _selectDate(date, builderContext),
                        onTimeChanged: null,
                        showTimeSelector: false,
                      ),
                    const SizedBox(height: 16),

                    // Slot Selector (only if branch and date are selected, and either loading, has slots, or has error)
                    if (_selectedBranchId != null &&
                        _selectedDate != null &&
                        (_isLoadingSlots ||
                            _availableSlots.isNotEmpty ||
                            _slotsError != null))
                      SlotSelector(
                        slots: _availableSlots,
                        selectedSlot: _selectedSlot,
                        slotMinutes: _slotMinutes,
                        selectedDurationHours: _durationHours,
                        isLoading: _isLoadingSlots,
                        errorMessage: _slotsError,
                        onSlotSelected: _onSlotSelected,
                      ),
                    // Message if slots are empty but branch and date are selected (and not loading, no error)
                    if (_selectedBranchId != null &&
                        _selectedDate != null &&
                        !_isLoadingSlots &&
                        _slotsError == null &&
                        _availableSlots.isEmpty)
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.info_circle,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'no_slots_available_for_date'.tr(),
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Duration
                    Builder(
                      builder: (durationContext) => TextFormField(
                        decoration: InputDecoration(
                          labelText: 'duration_hours'.tr(),
                          helperText:
                              _maxDurationForSlot != null &&
                                  _maxDurationForSlot! > 0
                              ? 'max_duration_hours'.tr(
                                  args: [_maxDurationForSlot.toString()],
                                )
                              : null,
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: _durationHours.toString(),
                        onChanged: (value) {
                          final hours = int.tryParse(value) ?? 2;
                          setState(() {
                            _durationHours = hours;
                          });
                          if (_selectedBranchId != null && _selectedDate != null) {
                            // Use WidgetsBinding to ensure context is available
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _fetchSlotsForDate(durationContext);
                                _computeMaxDurationFromSlots();
                              }
                            });
                          }
                        },
                        validator: (value) {
                          final hours = int.tryParse(value ?? '');
                          if (hours == null || hours < 1) {
                            return 'please_enter_valid_duration'.tr();
                          }
                          if (_maxDurationForSlot != null &&
                              _maxDurationForSlot! > 0 &&
                              hours > _maxDurationForSlot!) {
                            return 'duration_cannot_exceed'.tr(
                              args: [_maxDurationForSlot.toString()],
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Persons
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'persons_count'.tr(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _persons.toString(),
                      onChanged: (value) {
                        _persons = int.tryParse(value) ?? 10;
                      },
                      validator: (value) {
                        final persons = int.tryParse(value ?? '');
                        if (persons == null || persons < 1) {
                          return 'please_enter_valid_number'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Decorated
                    CheckboxListTile(
                      title: Text('decoration'.tr()),
                      value: _decorated,
                      onChanged: (value) =>
                          setState(() => _decorated = value ?? false),
                    ),

                    // Notes
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'notes_optional'.tr(),
                      ),
                      maxLines: 3,
                      onChanged: (value) => _notes = value,
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    BlocBuilder<EventRequestCubit, EventRequestState>(
                      builder: (context, state) {
                        final isLoading = state is EventRequestCreating;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => _submit(context),
                            child: isLoading
                                ? const CircularProgressIndicator()
                                : Text('submit_request'.tr()),
                          ),
                        );
                      },
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
